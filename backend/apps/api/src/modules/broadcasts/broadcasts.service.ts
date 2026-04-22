import { Injectable } from '@nestjs/common';
import { BroadcastCampaign, BroadcastStatus, Prisma, SystemRole } from '@prisma/client';
import { Clock, ErrorCodes, InvalidInputError, NotFoundError, PrismaService } from '@app/common';
import { AdminAuditService } from '../admin-audit/admin-audit.service';

export interface BroadcastFilter {
  roles?: SystemRole[];
  projectIds?: string[];
  userIds?: string[];
  bannedOnly?: boolean;
}

@Injectable()
export class BroadcastsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly audit: AdminAuditService,
  ) {}

  async previewTargets(
    filter: BroadcastFilter,
  ): Promise<{ count: number; sampleUserIds: string[] }> {
    const userIds = await this.resolveTargets(filter);
    return { count: userIds.length, sampleUserIds: userIds.slice(0, 10) };
  }

  async send(
    actorId: string,
    input: {
      title: string;
      body: string;
      deepLink?: string;
      filter: BroadcastFilter;
    },
  ): Promise<BroadcastCampaign> {
    const userIds = await this.resolveTargets(input.filter);
    if (userIds.length === 0) {
      throw new InvalidInputError(ErrorCodes.BROADCAST_EMPTY_TARGET, 'no users matched the filter');
    }

    const now = this.clock.now();
    const campaign = await this.prisma.broadcastCampaign.create({
      data: {
        title: input.title,
        body: input.body,
        deepLink: input.deepLink,
        filter: input.filter as unknown as Prisma.InputJsonValue,
        createdById: actorId,
        targetCount: userIds.length,
        queuedCount: userIds.length,
        status: BroadcastStatus.queued,
        createdAt: now,
      },
    });

    // Эмит через NotificationsService — делегируем наверх через event-emitter,
    // чтобы не тянуть циркулярную зависимость. На получающей стороне подписчик дёрнет FCM/Noop.
    // Для MVP — просто пишем NotificationLog напрямую (в staging это Noop).
    for (const userId of userIds) {
      await this.prisma.notificationLog.create({
        data: {
          userId,
          kind: 'membership_added', // reuse существующего enum; это broadcast — payload уточняет
          priority: 'normal',
          title: input.title,
          body: input.body,
          deepLink: input.deepLink,
          payload: { broadcastId: campaign.id, source: 'admin_broadcast' } as Prisma.InputJsonValue,
          sentAt: now,
          // deliveredAt/failedAt — ставит PushProcessor когда реально отправит.
          // В staging без FCM — помечаем delivered сразу.
          deliveredAt: now,
        },
      });
    }

    const updated = await this.prisma.broadcastCampaign.update({
      where: { id: campaign.id },
      data: {
        status: BroadcastStatus.sent,
        sentAt: this.clock.now(),
        deliveredCount: userIds.length,
      },
    });

    await this.audit.log({
      actorId,
      action: 'broadcast.send',
      targetType: 'BroadcastCampaign',
      targetId: campaign.id,
      metadata: {
        targetCount: userIds.length,
        filterKeys: Object.keys(input.filter),
      },
    });
    return updated;
  }

  async list(filters: { status?: BroadcastStatus; limit?: number } = {}) {
    return this.prisma.broadcastCampaign.findMany({
      where: filters.status ? { status: filters.status } : {},
      orderBy: { createdAt: 'desc' },
      take: Math.min(filters.limit ?? 50, 200),
    });
  }

  async get(id: string) {
    const c = await this.prisma.broadcastCampaign.findUnique({ where: { id } });
    if (!c) throw new NotFoundError(ErrorCodes.BROADCAST_NOT_FOUND, 'campaign not found');
    return c;
  }

  private async resolveTargets(filter: BroadcastFilter): Promise<string[]> {
    // Если явно указаны userIds — они priority over other filters (целевая рассылка).
    if (Array.isArray(filter.userIds) && filter.userIds.length > 0) {
      const found = await this.prisma.user.findMany({
        where: { id: { in: filter.userIds }, bannedAt: null },
        select: { id: true },
      });
      return found.map((u) => u.id);
    }

    const where: Prisma.UserWhereInput = {
      bannedAt: filter.bannedOnly ? { not: null } : null,
    };
    if (Array.isArray(filter.roles) && filter.roles.length > 0) {
      where.roles = { some: { role: { in: filter.roles } } };
    }
    if (Array.isArray(filter.projectIds) && filter.projectIds.length > 0) {
      where.OR = [
        { ownedProjects: { some: { id: { in: filter.projectIds } } } },
        { memberships: { some: { projectId: { in: filter.projectIds } } } },
      ];
    }
    const users = await this.prisma.user.findMany({
      where,
      select: { id: true },
      take: 5000,
    });
    return users.map((u) => u.id);
  }
}
