import { Injectable } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { ExportJob, ExportKind, ExportStatus, Prisma } from '@prisma/client';
import {
  Clock,
  ErrorCodes,
  NotFoundError,
  PrismaService,
  decodeCursor,
  encodeCursor,
} from '@app/common';
import { FilesService } from '@app/files';
import { FeedService } from '../feed/feed.service';
import { QUEUE_EXPORTS } from '../queues/queues.module';

const EXPORT_TTL_MS = 7 * 24 * 60 * 60 * 1000;

export interface FeedFilters {
  kind?: string[];
  stageId?: string;
  dateFrom?: string;
  dateTo?: string;
  actorId?: string;
}

/** Контекст наблюдателя ленты — для role-based видимости (TODO §2A.2). */
export interface FeedListViewer {
  userId: string;
  isOwner?: boolean;
  membershipRole?: 'customer' | 'representative' | 'foreman' | 'master';
  assignedStageIds?: string[];
  foremanStageIds?: string[];
}

@Injectable()
export class ExportService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly feed: FeedService,
    private readonly files: FilesService,
    @InjectQueue(QUEUE_EXPORTS) private readonly queue: Queue,
  ) {}

  async request(
    projectId: string,
    requestedById: string,
    kind: ExportKind,
    filters: FeedFilters,
  ): Promise<ExportJob> {
    const now = this.clock.now();
    const expiresAt = new Date(now.getTime() + EXPORT_TTL_MS);
    const job = await this.prisma.exportJob.create({
      data: {
        projectId,
        requestedById,
        kind,
        filtersPayload: filters as unknown as Prisma.InputJsonValue,
        status: ExportStatus.queued,
        expiresAt,
        createdAt: now,
      },
    });
    await this.queue.add(kind, { jobId: job.id }, { jobId: job.id, attempts: 2 });
    await this.feed.emit({
      kind: 'export_requested',
      projectId,
      actorId: requestedById,
      payload: { jobId: job.id, kind },
    });
    return job;
  }

  async get(jobId: string): Promise<ExportJob & { downloadUrl?: string }> {
    const job = await this.prisma.exportJob.findUnique({ where: { id: jobId } });
    if (!job) throw new NotFoundError(ErrorCodes.EXPORT_NOT_FOUND, 'export not found');
    if (job.status === 'expired' || job.expiresAt < this.clock.now()) {
      return { ...job };
    }
    let downloadUrl: string | undefined;
    if (job.status === 'done' && job.resultFileKey) {
      // Прокси через API (см. streamFile()) — никаких presigned S3 URL,
      // мобилке передаём прямой стрим с auth-хедером.
      downloadUrl = `/api/exports/${job.id}/file`;
    }
    return { ...job, downloadUrl };
  }

  async listForProject(
    projectId: string,
    requestedById: string,
  ): Promise<Array<ExportJob & { downloadUrl?: string }>> {
    const jobs = await this.prisma.exportJob.findMany({
      where: { projectId, requestedById },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    const now = this.clock.now();
    return jobs.map((job) => {
      if (job.status === 'done' && job.resultFileKey && job.expiresAt > now) {
        return { ...job, downloadUrl: `/api/exports/${job.id}/file` };
      }
      return job;
    });
  }

  /**
   * Стримит готовый файл экспорта (ZIP/PDF/TXT) клиенту. Использует наш
   * server-side minio-клиент — те же креды, та же сеть, что работает в
   * проде. Не требует от мобилки ходить напрямую в Selectel.
   */
  async streamFile(jobId: string): Promise<{
    stream: NodeJS.ReadableStream;
    mimeType: string;
    contentLength?: number;
    filename: string;
  }> {
    const job = await this.prisma.exportJob.findUnique({ where: { id: jobId } });
    if (!job) throw new NotFoundError(ErrorCodes.EXPORT_NOT_FOUND, 'export not found');
    if (job.status !== 'done' || !job.resultFileKey) {
      throw new NotFoundError(ErrorCodes.EXPORT_NOT_FOUND, 'export file not ready');
    }
    if (job.expiresAt < this.clock.now()) {
      throw new NotFoundError(ErrorCodes.EXPORT_NOT_FOUND, 'export expired');
    }
    const stream = await this.files.streamObject(job.resultFileKey);
    const mimeType = guessExportMime(job.kind, job.resultFileKey);
    const filename = buildExportFilename(job.kind, job.id, job.resultFileKey);
    return {
      stream,
      mimeType,
      contentLength: job.resultSizeBytes ?? undefined,
      filename,
    };
  }

  async markRunning(jobId: string): Promise<void> {
    await this.prisma.exportJob.update({
      where: { id: jobId },
      data: { status: ExportStatus.running, startedAt: this.clock.now() },
    });
  }

  async markDone(jobId: string, fileKey: string, sizeBytes: number): Promise<void> {
    const job = await this.prisma.exportJob.update({
      where: { id: jobId },
      data: {
        status: ExportStatus.done,
        resultFileKey: fileKey,
        resultSizeBytes: sizeBytes,
        progressPct: 100,
        finishedAt: this.clock.now(),
      },
    });
    await this.feed.emit({
      kind: 'export_completed',
      projectId: job.projectId,
      actorId: job.requestedById,
      payload: { jobId, kind: job.kind, sizeBytes },
    });
  }

  async markFailed(jobId: string, error: string): Promise<void> {
    const job = await this.prisma.exportJob.update({
      where: { id: jobId },
      data: { status: ExportStatus.failed, error, finishedAt: this.clock.now() },
    });
    await this.feed.emit({
      kind: 'export_failed',
      projectId: job.projectId,
      actorId: job.requestedById,
      payload: { jobId, error },
    });
  }

  // ---------- Feed listing with cursor ----------

  async listFeed(
    projectId: string,
    q: FeedFilters & { cursor?: string; limit?: number },
    viewer?: FeedListViewer,
  ) {
    const limit = Math.min(Math.max(q.limit ?? 50, 1), 200);
    const cursor = decodeCursor<{ createdAtIso: string; id: string }>(q.cursor);

    const ands: Prisma.FeedEventWhereInput[] = [];
    if (q.stageId) {
      // Поддерживаем оба варианта: новый stageId column и старый payload.stageId (бэкфилл).
      ands.push({
        OR: [
          { stageId: q.stageId },
          { stageId: null, payload: { path: ['stageId'], equals: q.stageId } },
        ],
      });
    }

    // Role-based видимость по матрице 2A.2:
    if (viewer && !viewer.isOwner && viewer.membershipRole !== 'representative') {
      if (viewer.membershipRole === 'master') {
        const stages = viewer.assignedStageIds ?? [];
        ands.push({
          OR: [{ stageId: null }, { stageId: { in: stages } }],
        });
      } else if (viewer.membershipRole === 'foreman') {
        const stages = [...(viewer.foremanStageIds ?? []), ...(viewer.assignedStageIds ?? [])];
        ands.push({
          OR: [{ stageId: null }, { stageId: { in: stages } }],
        });
      }
    }

    const where: Prisma.FeedEventWhereInput = {
      projectId,
      ...(Array.isArray(q.kind) && q.kind.length > 0 ? { kind: { in: q.kind as any } } : {}),
      ...(q.actorId ? { actorId: q.actorId } : {}),
      ...(q.dateFrom || q.dateTo
        ? {
            createdAt: {
              ...(q.dateFrom ? { gte: new Date(q.dateFrom) } : {}),
              ...(q.dateTo ? { lte: new Date(q.dateTo) } : {}),
            },
          }
        : {}),
      ...(cursor
        ? {
            OR: [
              { createdAt: { lt: new Date(cursor.createdAtIso) } },
              { createdAt: new Date(cursor.createdAtIso), id: { lt: cursor.id } },
            ],
          }
        : {}),
      ...(ands.length > 0 ? { AND: ands } : {}),
    };
    const items = await this.prisma.feedEvent.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
    });
    const hasMore = items.length > limit;
    const page = items.slice(0, limit);
    const nextCursor = hasMore
      ? encodeCursor({
          createdAtIso: page[page.length - 1].createdAt.toISOString(),
          id: page[page.length - 1].id,
        })
      : null;
    return { items: page, nextCursor };
  }
}

function guessExportMime(kind: ExportKind, key: string): string {
  if (key.endsWith('.zip')) return 'application/zip';
  if (key.endsWith('.pdf')) return 'application/pdf';
  if (key.endsWith('.txt')) return 'text/plain; charset=utf-8';
  // Fallback по kind
  switch (kind) {
    case 'feed_pdf':
    case 'project_report_pdf':
      return 'application/pdf';
    case 'project_zip':
      return 'application/zip';
    default:
      return 'application/octet-stream';
  }
}

function buildExportFilename(kind: ExportKind, jobId: string, key: string): string {
  // Берём расширение из ключа, базовое имя — kind + короткий jobId.
  const ext = key.includes('.') ? key.slice(key.lastIndexOf('.')) : '';
  return `${kind}_${jobId.slice(0, 8)}${ext}`;
}
