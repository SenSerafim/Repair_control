import { Injectable } from '@nestjs/common';
import { Document, DocumentCategory, Prisma } from '@prisma/client';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { nanoid } from 'nanoid';
import {
  Clock,
  ConflictError,
  ErrorCodes,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { FilesService } from '@app/files';
import { FeedService } from '../feed/feed.service';
import { QUEUE_DOCUMENT_THUMBNAILS } from '../queues/queues.module';
import { PresignUploadDto } from './dto';

/**
 * Контекст наблюдателя для проверки видимости документов (TODO §2A.2).
 * Заполняется в контроллере на основе Membership + RepresentativeRights.
 */
export interface DocumentViewer {
  userId: string;
  isOwner?: boolean;
  membershipRole?: 'customer' | 'representative' | 'foreman' | 'master';
  canSeeBudget?: boolean;
}

@Injectable()
export class DocumentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly files: FilesService,
    private readonly feed: FeedService,
    @InjectQueue(QUEUE_DOCUMENT_THUMBNAILS)
    private readonly thumbQueue: Queue,
  ) {}

  async presignUpload(projectId: string, actorUserId: string, dto: PresignUploadDto) {
    const id = nanoid();
    const scope = `docs/${projectId}/${id}`;
    const up = await this.files.createPresignedUpload({
      scope,
      filename: dto.title,
      mimeType: dto.mimeType,
      sizeBytes: dto.sizeBytes,
    });
    const doc = await this.prisma.document.create({
      data: {
        id,
        projectId,
        stageId: dto.stageId ?? null,
        stepId: dto.stepId ?? null,
        category: dto.category,
        title: dto.title,
        fileKey: up.key,
        mimeType: dto.mimeType,
        sizeBytes: dto.sizeBytes,
        uploadedById: actorUserId,
        thumbStatus: 'pending',
      },
    });
    return {
      documentId: doc.id,
      uploadUrl: up.uploadUrl,
      key: up.key,
      expiresAt: up.expiresAt,
    };
  }

  async confirm(documentId: string, actorUserId: string): Promise<Document> {
    const doc = await this.prisma.document.findUnique({ where: { id: documentId } });
    if (!doc) throw new NotFoundError(ErrorCodes.DOCUMENT_NOT_FOUND, 'document not found');
    if (doc.deletedAt) throw new ConflictError(ErrorCodes.DOCUMENT_DELETED, 'document deleted');
    // Проверяем, что файл реально лежит в S3-хранилище
    try {
      await this.files.statObject(doc.fileKey);
    } catch {
      throw new InvalidInputError(
        ErrorCodes.DOCUMENT_FILE_MISSING,
        'uploaded file not found in storage',
      );
    }
    // Enqueue thumbnail для PDF
    if (doc.mimeType === 'application/pdf' && doc.thumbStatus === 'pending') {
      await this.thumbQueue.add('generate', { documentId: doc.id }, { jobId: `thumb:${doc.id}` });
    } else if (doc.mimeType !== 'application/pdf') {
      await this.prisma.document.update({
        where: { id: documentId },
        data: { thumbStatus: 'skipped' },
      });
    }
    await this.feed.emit({
      kind: 'document_uploaded',
      projectId: doc.projectId,
      actorId: actorUserId,
      payload: { documentId: doc.id, category: doc.category, stageId: doc.stageId },
    });
    const fresh = (await this.prisma.document.findUnique({
      where: { id: documentId },
    })) as Document;
    return this.attachUrls(fresh);
  }

  async list(
    projectId: string,
    filters: { stageId?: string; stepId?: string; category?: DocumentCategory; q?: string } = {},
    viewer?: DocumentViewer,
  ): Promise<Document[]> {
    const where: Prisma.DocumentWhereInput = {
      projectId,
      deletedAt: null,
      ...(filters.stageId ? { stageId: filters.stageId } : {}),
      ...(filters.stepId ? { stepId: filters.stepId } : {}),
      ...(filters.q
        ? {
            OR: [{ title: { contains: filters.q, mode: 'insensitive' } }],
          }
        : {}),
    };

    // Категорийная видимость по роли (TODO §2A.2):
    // master не видит contract/act/estimate;
    // representative без canSeeBudget не видит estimate.
    const blocked: DocumentCategory[] = [];
    if (viewer?.membershipRole === 'master') {
      blocked.push('contract', 'act', 'estimate');
    } else if (viewer?.membershipRole === 'representative' && viewer.canSeeBudget !== true) {
      blocked.push('estimate');
    }
    if (filters.category) {
      if (blocked.includes(filters.category)) {
        return [];
      }
      where.category = filters.category;
    } else if (blocked.length > 0) {
      where.category = { notIn: blocked };
    }

    const docs = await this.prisma.document.findMany({ where, orderBy: { createdAt: 'desc' } });
    return Promise.all(docs.map((d) => this.attachUrls(d)));
  }

  async get(id: string, viewer?: DocumentViewer): Promise<Document> {
    const doc = await this.prisma.document.findUnique({ where: { id } });
    if (!doc || doc.deletedAt) {
      throw new NotFoundError(ErrorCodes.DOCUMENT_NOT_FOUND, 'document not found');
    }
    if (viewer && viewer.membershipRole === 'master') {
      const restricted: DocumentCategory[] = ['contract', 'act', 'estimate'];
      if (restricted.includes(doc.category)) {
        throw new ForbiddenError(ErrorCodes.FORBIDDEN, 'document category forbidden for master');
      }
    }
    if (
      viewer &&
      viewer.membershipRole === 'representative' &&
      viewer.canSeeBudget !== true &&
      doc.category === 'estimate'
    ) {
      throw new ForbiddenError(ErrorCodes.FORBIDDEN, 'estimate hidden without canSeeBudget');
    }
    return this.attachUrls(doc);
  }

  async download(id: string): Promise<{ url: string; expiresAt: Date }> {
    const doc = await this.get(id);
    return this.files.createPresignedDownload(doc.fileKey);
  }

  async thumbnail(id: string): Promise<{ url: string; expiresAt: Date }> {
    const doc = await this.get(id);
    if (doc.thumbStatus !== 'done' || !doc.thumbKey) {
      throw new NotFoundError(ErrorCodes.DOCUMENT_NOT_FOUND, 'thumbnail not ready');
    }
    return this.files.createPresignedDownload(doc.thumbKey);
  }

  async patch(
    id: string,
    actorUserId: string,
    input: { title?: string; category?: DocumentCategory; stageId?: string; stepId?: string },
  ): Promise<Document> {
    const doc = await this.get(id);
    const updated = await this.prisma.document.update({
      where: { id },
      data: {
        ...(input.title !== undefined ? { title: input.title } : {}),
        ...(input.category !== undefined ? { category: input.category } : {}),
        ...(input.stageId !== undefined ? { stageId: input.stageId } : {}),
        ...(input.stepId !== undefined ? { stepId: input.stepId } : {}),
      },
    });
    await this.feed.emit({
      kind: 'document_updated',
      projectId: doc.projectId,
      actorId: actorUserId,
      payload: { documentId: id, changes: input },
    });
    return updated;
  }

  async softDelete(id: string, actorUserId: string): Promise<void> {
    const doc = await this.get(id);
    await this.prisma.document.update({
      where: { id },
      data: { deletedAt: this.clock.now() },
    });
    await this.feed.emit({
      kind: 'document_deleted',
      projectId: doc.projectId,
      actorId: actorUserId,
      payload: { documentId: id },
    });
  }

  /**
   * Прикрепляет presigned `url` (для inline-просмотра в мобильном/admin) и
   * `thumbUrl` (PDF-превью или то же изображение для image/*).
   *
   * Если presign провалится (S3 недоступен) — возвращаем документ без url:
   * клиент покажет иконку категории, ссылка на download остаётся доступна
   * через `GET /documents/:id/download`.
   */
  private async attachUrls<
    T extends { fileKey: string; thumbKey: string | null; mimeType: string },
  >(doc: T): Promise<T & { url: string | null; thumbUrl: string | null }> {
    let url: string | null = null;
    let thumbUrl: string | null = null;
    try {
      url = (await this.files.createPresignedDownload(doc.fileKey)).url;
    } catch {
      url = null;
    }
    try {
      if (doc.thumbKey) {
        thumbUrl = (await this.files.createPresignedDownload(doc.thumbKey)).url;
      } else if (doc.mimeType.startsWith('image/')) {
        // Для изображений отдельной thumbnail нет — используем сам файл.
        thumbUrl = url;
      }
    } catch {
      thumbUrl = null;
    }
    return { ...doc, url, thumbUrl };
  }
}
