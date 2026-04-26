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
      const { url } = await this.files.createPresignedDownload(job.resultFileKey);
      downloadUrl = url;
    }
    return { ...job, downloadUrl };
  }

  async listForProject(projectId: string, requestedById: string): Promise<ExportJob[]> {
    return this.prisma.exportJob.findMany({
      where: { projectId, requestedById },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
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
