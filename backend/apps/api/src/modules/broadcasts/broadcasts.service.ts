import { Injectable } from '@nestjs/common';
import {
  BroadcastCampaign,
  BroadcastStatus,
  DevicePlatform,
  Prisma,
  SystemRole,
} from '@prisma/client';
import { Clock, ErrorCodes, InvalidInputError, NotFoundError, PrismaService } from '@app/common';
import { AdminAuditService } from '../admin-audit/admin-audit.service';
import { NotificationsService } from '../notifications/notifications.service';

export interface BroadcastFilter {
  roles?: SystemRole[];
  projectIds?: string[];
  userIds?: string[];
  bannedOnly?: boolean;
  /** Сужение по платформе зарегистрированных device tokens (filtering after user resolution). */
  platform?: DevicePlatform;
}

@Injectable()
export class BroadcastsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly audit: AdminAuditService,
    private readonly notifications: NotificationsService,
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

    // Делегируем NotificationsService — он ставит jobs в BullMQ-очередь push,
    // а PushProcessor пишет NotificationLog с deliveredAt/failedAt по факту отправки.
    // template.render для 'admin_announcement' берёт title/body из payload.
    await this.notifications.dispatch({
      userIds,
      kind: 'admin_announcement',
      deepLink: input.deepLink,
      payload: {
        title: input.title,
        body: input.body,
        broadcastId: campaign.id,
        source: 'admin_broadcast',
      },
    });

    const updated = await this.prisma.broadcastCampaign.update({
      where: { id: campaign.id },
      data: {
        status: BroadcastStatus.sent,
        sentAt: this.clock.now(),
        // deliveredCount ставит фон-job по факту реальной доставки. Здесь — queued.
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
        platform: input.filter.platform ?? null,
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
    let userIds: string[];

    // Если явно указаны userIds — они priority over other filters (целевая рассылка).
    if (Array.isArray(filter.userIds) && filter.userIds.length > 0) {
      const found = await this.prisma.user.findMany({
        where: { id: { in: filter.userIds }, bannedAt: null },
        select: { id: true },
      });
      userIds = found.map((u) => u.id);
    } else {
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
      userIds = users.map((u) => u.id);
    }

    if (userIds.length === 0) return userIds;

    // Пост-фильтр по платформе: оставляем только тех, у кого хоть один
    // зарегистрированный device token указанной платформы.
    if (filter.platform) {
      const tokenized = await this.prisma.deviceToken.findMany({
        where: { userId: { in: userIds }, platform: filter.platform },
        select: { userId: true },
        distinct: ['userId'],
      });
      const allowed = new Set(tokenized.map((t) => t.userId));
      userIds = userIds.filter((id) => allowed.has(id));
    }

    return userIds;
  }
}
