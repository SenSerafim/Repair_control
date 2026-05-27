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
        description: dto.description?.trim() ? dto.description.trim() : null,
        documentDate: dto.documentDate ? new Date(dto.documentDate) : null,
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

  /**
   * Server-side multipart upload — заменяет presign+PUT+confirm одним вызовом.
   * Используется мобилкой как основной путь: presigned-PUT в Selectel
   * нестабилен с части устройств (TLS / chunked TE / DNS бакет-субдомена).
   * Здесь файл уже на сервере (multer), мы кладём его в S3 нашим Node-клиентом
   * (тот же путь, что в exports/thumbnails — проверен в проде).
   */
  async uploadDocument(
    projectId: string,
    actorUserId: string,
    file: { buffer: Buffer; mimeType: string; size: number; originalName?: string },
    meta: {
      category: DocumentCategory;
      title: string;
      stageId?: string;
      stepId?: string;
      description?: string;
      documentDate?: string;
    },
  ): Promise<Document> {
    const id = nanoid();
    const scope = `docs/${projectId}/${id}`;
    this.files.validate({
      scope,
      filename: meta.title,
      mimeType: file.mimeType,
      sizeBytes: file.size,
    });
    const key = this.files.buildKey({
      scope,
      filename: meta.title,
      mimeType: file.mimeType,
      sizeBytes: file.size,
    });
    await this.files.putObject(key, file.buffer, file.mimeType);

    const doc = await this.prisma.document.create({
      data: {
        id,
        projectId,
        stageId: meta.stageId ?? null,
        stepId: meta.stepId ?? null,
        category: meta.category,
        title: meta.title,
        description: meta.description?.trim() ? meta.description.trim() : null,
        documentDate: meta.documentDate ? new Date(meta.documentDate) : null,
        fileKey: key,
        mimeType: file.mimeType,
        sizeBytes: file.size,
        uploadedById: actorUserId,
        thumbStatus: 'pending',
      },
    });

    if (file.mimeType === 'application/pdf') {
      await this.thumbQueue.add('generate', { documentId: doc.id }, { jobId: `thumb:${doc.id}` });
    } else {
      await this.prisma.document.update({
        where: { id: doc.id },
        data: { thumbStatus: 'skipped' },
      });
    }
    await this.feed.emit({
      kind: 'document_uploaded',
      projectId: doc.projectId,
      actorId: actorUserId,
      payload: { documentId: doc.id, category: doc.category, stageId: doc.stageId },
    });
    const fresh = (await this.prisma.document.findUnique({ where: { id: doc.id } })) as Document;
    return this.attachUrls(fresh);
  }

  /**
   * Стримит файл документа через API (без редиректа на S3). См. attachUrls():
   * url теперь указывает сюда, не на presigned-URL Selectel — мобилка может
   * скачать через тот же dio (auth-интерсептор сам положит Bearer) или
   * показать inline через cached_network_image с httpHeaders.
   */
  async streamFile(
    id: string,
    viewer?: DocumentViewer,
  ): Promise<{
    stream: NodeJS.ReadableStream;
    mimeType: string;
    contentLength: number;
    filename: string;
  }> {
    const doc = await this.get(id, viewer);
    const stream = await this.files.streamObject(doc.fileKey);
    return {
      stream,
      mimeType: doc.mimeType,
      contentLength: doc.sizeBytes,
      filename: doc.title,
    };
  }

  async streamThumbnail(
    id: string,
    viewer?: DocumentViewer,
  ): Promise<{ stream: NodeJS.ReadableStream; mimeType: string }> {
    const doc = await this.get(id, viewer);
    if (doc.thumbStatus !== 'done' || !doc.thumbKey) {
      throw new NotFoundError(ErrorCodes.DOCUMENT_NOT_FOUND, 'thumbnail not ready');
    }
    const stream = await this.files.streamObject(doc.thumbKey);
    return { stream, mimeType: 'image/jpeg' };
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
    return docs.map((d) => this.attachUrls(d));
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

  /**
   * Возвращает относительный путь стрим-эндпоинта (`/api/documents/:id/file`).
   * Мобилка/admin сами клеят baseUrl и шлют запрос с Authorization-хедером —
   * никаких redirect на S3 и проблем с TLS у Selectel на старых девайсах.
   * Поле `expiresAt` оставлено для обратной совместимости старого контракта.
   */
  async download(id: string): Promise<{ url: string; expiresAt: Date }> {
    const doc = await this.get(id);
    return {
      url: `/api/documents/${doc.id}/file`,
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
    };
  }

  async thumbnail(id: string): Promise<{ url: string; expiresAt: Date }> {
    const doc = await this.get(id);
    if (doc.thumbStatus !== 'done' || !doc.thumbKey) {
      throw new NotFoundError(ErrorCodes.DOCUMENT_NOT_FOUND, 'thumbnail not ready');
    }
    return {
      url: `/api/documents/${doc.id}/thumbnail-file`,
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
    };
  }

  async patch(
    id: string,
    actorUserId: string,
    input: {
      title?: string;
      category?: DocumentCategory;
      stageId?: string;
      stepId?: string;
      description?: string;
      documentDate?: string;
    },
  ): Promise<Document> {
    const doc = await this.get(id);
    const updated = await this.prisma.document.update({
      where: { id },
      data: {
        ...(input.title !== undefined ? { title: input.title } : {}),
        ...(input.category !== undefined ? { category: input.category } : {}),
        ...(input.stageId !== undefined ? { stageId: input.stageId } : {}),
        ...(input.stepId !== undefined ? { stepId: input.stepId } : {}),
        ...(input.description !== undefined
          ? { description: input.description.trim() ? input.description.trim() : null }
          : {}),
        ...(input.documentDate !== undefined
          ? { documentDate: input.documentDate ? new Date(input.documentDate) : null }
          : {}),
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
   * Прикрепляет относительные `url` / `thumbUrl` указывающие на стрим-эндпоинты API.
   * Полную ссылку собирает клиент: `${env.apiBaseUrl}${doc.url}`. Запрос идёт
   * с Authorization-хедером через тот же dio/fetch, что и REST. Преимущества
   * перед presigned-URL Selectel:
   *   - нет проблем с TLS-кэшем на эмуляторах / старых Android;
   *   - нет несовместимости host-styled bucket subdomain (DNS на части сетей);
   *   - нет CORS, redirect, chunked-TE и signature-mismatch на upload;
   *   - сервер сам решает фильтрацию по правам (RBAC через guard).
   */
  private attachUrls<T extends { id: string; thumbKey: string | null; mimeType: string }>(
    doc: T,
  ): T & { url: string; thumbUrl: string | null } {
    const url = `/api/documents/${doc.id}/file`;
    let thumbUrl: string | null = null;
    if (doc.thumbKey) {
      thumbUrl = `/api/documents/${doc.id}/thumbnail-file`;
    } else if (doc.mimeType.startsWith('image/')) {
      // У изображений отдельной thumbnail нет — клиент сам decode'ит превью.
      thumbUrl = url;
    }
    return { ...doc, url, thumbUrl };
  }
}
