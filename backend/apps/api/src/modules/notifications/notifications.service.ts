import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { NotificationKind, NotificationPriority, Prisma } from '@prisma/client';
import { Clock, ErrorCodes, InvalidInputError, PrismaService } from '@app/common';
import { QUEUE_PUSH } from '../queues/queues.module';
import { isCritical, NOTIFICATION_TEMPLATES } from './notification-templates';

export interface DispatchInput {
  userIds: string[];
  kind: NotificationKind;
  projectId?: string | null;
  payload?: Record<string, unknown>;
  deepLink?: string;
}

/**
 * Высокоуровневый сервис уведомлений. Определяет, кому и какие пуши отправлять,
 * уважает настройки (critical нельзя отключить), эмитит job в BullMQ-очередь push.
 */
@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly events: EventEmitter2,
    @InjectQueue(QUEUE_PUSH) private readonly pushQueue: Queue,
  ) {}

  async dispatch(input: DispatchInput): Promise<void> {
    const template = NOTIFICATION_TEMPLATES[input.kind];
    if (!template) {
      throw new InvalidInputError(
        ErrorCodes.NOTIFICATIONS_UNKNOWN_KIND,
        `unknown kind ${input.kind}`,
      );
    }
    const { title, body } = template.render(input.payload ?? {});

    // Фильтруем получателей по их settings (critical всегда доставляется)
    const recipients = await this.filterRecipientsBySettings(
      input.userIds,
      input.kind,
      template.priority,
    );
    for (const userId of recipients) {
      await this.pushQueue.add(
        'send',
        {
          userId,
          kind: input.kind,
          priority: template.priority,
          title,
          body,
          deepLink: input.deepLink,
          projectId: input.projectId ?? null,
          payload: input.payload ?? {},
        },
        { jobId: `push:${input.kind}:${userId}:${Date.now()}` },
      );
      this.events.emit('notification.dispatched', {
        userId,
        kind: input.kind,
        title,
        body,
        deepLink: input.deepLink,
      });
    }
  }

  private async filterRecipientsBySettings(
    userIds: string[],
    kind: NotificationKind,
    priority: NotificationPriority,
  ): Promise<string[]> {
    if (priority === 'critical') return Array.from(new Set(userIds));
    const settings = await this.prisma.notificationSetting.findMany({
      where: { userId: { in: userIds }, kind },
      select: { userId: true, pushEnabled: true },
    });
    const disabled = new Set(settings.filter((s) => !s.pushEnabled).map((s) => s.userId));
    return userIds.filter((u) => !disabled.has(u));
  }

  // ---------- Settings CRUD (self) ----------

  async getSettings(userId: string): Promise<
    Array<{
      kind: NotificationKind;
      pushEnabled: boolean;
      priority: NotificationPriority;
      critical: boolean;
    }>
  > {
    const overrides = await this.prisma.notificationSetting.findMany({ where: { userId } });
    const byKind = new Map(overrides.map((s) => [s.kind, s.pushEnabled]));
    return Object.values(NOTIFICATION_TEMPLATES).map((tpl) => ({
      kind: tpl.kind,
      priority: tpl.priority,
      critical: tpl.priority === 'critical',
      pushEnabled: byKind.get(tpl.kind) ?? true,
    }));
  }

  async patchSetting(userId: string, kind: NotificationKind, pushEnabled: boolean): Promise<void> {
    if (!NOTIFICATION_TEMPLATES[kind]) {
      throw new InvalidInputError(ErrorCodes.NOTIFICATIONS_UNKNOWN_KIND, `unknown kind ${kind}`);
    }
    if (isCritical(kind) && !pushEnabled) {
      throw new InvalidInputError(
        ErrorCodes.NOTIFICATIONS_CANNOT_DISABLE_CRITICAL,
        `cannot disable critical notification: ${kind}`,
      );
    }
    await this.prisma.notificationSetting.upsert({
      where: { userId_kind: { userId, kind } },
      create: { userId, kind, pushEnabled },
      update: { pushEnabled },
    });
  }

  async adminLogs(filters: {
    userId?: string;
    kind?: NotificationKind;
    from?: string;
    to?: string;
  }) {
    const where: Prisma.NotificationLogWhereInput = {
      ...(filters.userId ? { userId: filters.userId } : {}),
      ...(filters.kind ? { kind: filters.kind } : {}),
      ...(filters.from || filters.to
        ? {
            sentAt: {
              ...(filters.from ? { gte: new Date(filters.from) } : {}),
              ...(filters.to ? { lte: new Date(filters.to) } : {}),
            },
          }
        : {}),
    };
    return this.prisma.notificationLog.findMany({
      where,
      orderBy: { sentAt: 'desc' },
      take: 100,
    });
  }
}
