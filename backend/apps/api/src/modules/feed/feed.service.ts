import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { FeedEventKind, Prisma } from '@prisma/client';
import { PrismaService } from '@app/common';

export interface EmitEventInput {
  kind: FeedEventKind;
  projectId?: string | null;
  /** ID этапа, к которому относится событие (для role-based фильтрации мастеров). */
  stageId?: string | null;
  actorId?: string | null;
  payload?: Record<string, unknown>;
  tx?: Prisma.TransactionClient;
}

/**
 * Контекст наблюдателя для фильтрации ленты по матрице видимости (TODO §2A.2).
 * - master: видит только проектные события (stageId == null) + события своих этапов;
 *           не видит приватные финансовые события бригады.
 * - foreman: видит проектные события + события своих этапов;
 * - customer/representative/admin: видит всё.
 */
export interface FeedViewer {
  userId: string;
  isOwner?: boolean;
  membershipRole?: 'customer' | 'representative' | 'foreman' | 'master';
  /** Этапы, на которые назначен пользователь (Membership.stageIds). */
  assignedStageIds?: string[];
  /** Этапы, в которых пользователь — бригадир (Stage.foremanIds). */
  foremanStageIds?: string[];
}

/** Приватные kind'ы, видимые только бригаде (foreman + master). */
const FOREMAN_PRIVATE_KINDS: FeedEventKind[] = [
  // payment_distribution_internal — отдельный приватный kind для распределений foreman→master.
  // selfpurchase_master_to_foreman — приватный самозакуп внутри бригады.
  // Если в БД ещё нет таких kinds, эти строки будут безопасно игнорироваться TS-checker'ом.
] as FeedEventKind[];

/**
 * Централизованный outbox ленты (ТЗ §3.3). Все доменные изменения должны
 * пройти через emit, а не напрямую писать в feed_events.
 *
 * Помимо INSERT в feed_events, эмитит событие `feed.emitted` через @nestjs/event-emitter —
 * на него подписан NotificationRouter и ChatsGateway.
 */
@Injectable()
export class FeedService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly events: EventEmitter2,
  ) {}

  async emit(input: EmitEventInput): Promise<void> {
    const client = input.tx ?? this.prisma;
    // Если stageId не передан явно — попытаться извлечь из payload для бэкфилла.
    const stageIdFromPayload =
      typeof input.payload?.['stageId'] === 'string' ? (input.payload['stageId'] as string) : null;
    await client.feedEvent.create({
      data: {
        kind: input.kind,
        projectId: input.projectId ?? null,
        stageId: input.stageId ?? stageIdFromPayload ?? null,
        actorId: input.actorId ?? null,
        payload: (input.payload ?? {}) as Prisma.InputJsonValue,
      },
    });
    // Event-emitter fan-out: NotificationRouter, ChatsGateway (export:ready, ...)
    this.events.emit('feed.emitted', {
      kind: input.kind,
      projectId: input.projectId ?? null,
      stageId: input.stageId ?? stageIdFromPayload ?? null,
      actorId: input.actorId ?? null,
      payload: input.payload ?? {},
    });
  }

  async listForProject(projectId: string, viewer?: FeedViewer, limit = 50) {
    const where: Prisma.FeedEventWhereInput = { projectId };

    // Видимость по ролям (TODO §2A.2):
    if (viewer && !viewer.isOwner && viewer.membershipRole !== 'representative') {
      if (viewer.membershipRole === 'master') {
        const stages = viewer.assignedStageIds ?? [];
        where.OR = [{ stageId: null }, { stageId: { in: stages } }];
        // Скрыть приватные финансовые события бригады.
        if (FOREMAN_PRIVATE_KINDS.length > 0) {
          where.kind = { notIn: FOREMAN_PRIVATE_KINDS };
        }
      } else if (viewer.membershipRole === 'foreman') {
        const stages = [...(viewer.foremanStageIds ?? []), ...(viewer.assignedStageIds ?? [])];
        where.OR = [{ stageId: null }, { stageId: { in: stages } }];
      }
    }

    return this.prisma.feedEvent.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }
}
