import { Injectable } from '@nestjs/common';
import { Document, DocumentCategory, Prisma } from '@prisma/client';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { nanoid } from 'nanoid';
import {
  Clock,
  ConflictError,
  ErrorCodes,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { FilesService } from '@app/files';
import { FeedService } from '../feed/feed.service';
import { QUEUE_DOCUMENT_THUMBNAILS } from '../queues/queues.module';
import { PresignUploadDto } from './dto';

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
    return this.prisma.document.findUnique({ where: { id: documentId } }) as unknown as Document;
  }

  async list(
    projectId: string,
    filters: { stageId?: string; stepId?: string; category?: DocumentCategory; q?: string } = {},
  ): Promise<Document[]> {
    const where: Prisma.DocumentWhereInput = {
      projectId,
      deletedAt: null,
      ...(filters.stageId ? { stageId: filters.stageId } : {}),
      ...(filters.stepId ? { stepId: filters.stepId } : {}),
      ...(filters.category ? { category: filters.category } : {}),
      ...(filters.q
        ? {
            OR: [{ title: { contains: filters.q, mode: 'insensitive' } }],
          }
        : {}),
    };
    return this.prisma.document.findMany({ where, orderBy: { createdAt: 'desc' } });
  }

  async get(id: string): Promise<Document> {
    const doc = await this.prisma.document.findUnique({ where: { id } });
    if (!doc || doc.deletedAt) {
      throw new NotFoundError(ErrorCodes.DOCUMENT_NOT_FOUND, 'document not found');
    }
    return doc;
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
}
