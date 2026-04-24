import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { FeedEventKind, Prisma } from '@prisma/client';
import { PrismaService } from '@app/common';

export interface EmitEventInput {
  kind: FeedEventKind;
  projectId?: string | null;
  actorId?: string | null;
  payload?: Record<string, unknown>;
  tx?: Prisma.TransactionClient;
}

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
    await client.feedEvent.create({
      data: {
        kind: input.kind,
        projectId: input.projectId ?? null,
        actorId: input.actorId ?? null,
        payload: (input.payload ?? {}) as Prisma.InputJsonValue,
      },
    });
    // Event-emitter fan-out: NotificationRouter, ChatsGateway (export:ready, ...)
    this.events.emit('feed.emitted', {
      kind: input.kind,
      projectId: input.projectId ?? null,
      actorId: input.actorId ?? null,
      payload: input.payload ?? {},
    });
  }

  async listForProject(projectId: string, limit = 50) {
    return this.prisma.feedEvent.findMany({
      where: { projectId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }
}
