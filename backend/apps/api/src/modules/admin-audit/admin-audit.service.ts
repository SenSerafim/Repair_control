import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { Clock, PrismaService } from '@app/common';

export interface AuditInput {
  actorId: string;
  action: string;
  targetType?: string;
  targetId?: string;
  metadata?: Record<string, unknown>;
}

@Injectable()
export class AdminAuditService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
  ) {}

  async log(input: AuditInput): Promise<void> {
    await this.prisma.adminAuditLog.create({
      data: {
        actorId: input.actorId,
        action: input.action,
        targetType: input.targetType,
        targetId: input.targetId,
        metadata: (input.metadata ?? {}) as Prisma.InputJsonValue,
        createdAt: this.clock.now(),
      },
    });
  }

  async list(
    filters: { actorId?: string; action?: string; from?: string; to?: string; limit?: number } = {},
  ) {
    const where: Prisma.AdminAuditLogWhereInput = {
      ...(filters.actorId ? { actorId: filters.actorId } : {}),
      ...(filters.action ? { action: { contains: filters.action } } : {}),
      ...(filters.from || filters.to
        ? {
            createdAt: {
              ...(filters.from ? { gte: new Date(filters.from) } : {}),
              ...(filters.to ? { lte: new Date(filters.to) } : {}),
            },
          }
        : {}),
    };
    return this.prisma.adminAuditLog.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: Math.min(filters.limit ?? 100, 500),
    });
  }
}
