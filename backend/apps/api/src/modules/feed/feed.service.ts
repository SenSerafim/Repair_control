import { Injectable } from '@nestjs/common';
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
 */
@Injectable()
export class FeedService {
  constructor(private readonly prisma: PrismaService) {}

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
  }

  async listForProject(projectId: string, limit = 50) {
    return this.prisma.feedEvent.findMany({
      where: { projectId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }
}
