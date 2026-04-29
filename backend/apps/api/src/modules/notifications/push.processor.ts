import { Inject, Injectable, Logger } from '@nestjs/common';
import { Processor, WorkerHost } from '@nestjs/bullmq';
import type { Job } from 'bullmq';
import { Clock, PrismaService } from '@app/common';
import { QUEUE_PUSH } from '../queues/queues.module';
import { NOTIFICATION_PROVIDER, NotificationProvider } from './notification-provider.interface';
import { NotificationKind, NotificationPriority } from '@prisma/client';

export interface PushJobData {
  userId: string;
  kind: NotificationKind;
  priority: NotificationPriority;
  title: string;
  body: string;
  deepLink?: string;
  projectId?: string | null;
  payload?: Record<string, unknown>;
}

@Processor(QUEUE_PUSH)
@Injectable()
export class PushProcessor extends WorkerHost {
  private readonly logger = new Logger(PushProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    @Inject(NOTIFICATION_PROVIDER) private readonly provider: NotificationProvider,
  ) {
    super();
  }

  async process(job: Job<PushJobData>): Promise<void> {
    const data = job.data;
    const tokens = await this.prisma.deviceToken.findMany({ where: { userId: data.userId } });
    if (tokens.length === 0) {
      await this.log(data, null, 'failed', 'no_device_tokens');
      return;
    }
    for (const t of tokens) {
      const res = await this.provider.send(t.token, {
        title: data.title,
        body: data.body,
        data: {
          kind: data.kind,
          projectId: data.projectId ?? '',
          deepLink: data.deepLink ?? '',
        },
      });
      if (res.success) {
        await this.log(data, t.id, 'delivered');
      } else {
        await this.log(data, t.id, 'failed', res.error);
        if (res.tokenInvalid) {
          await this.prisma.deviceToken.delete({ where: { id: t.id } }).catch(() => void 0);
        }
      }
    }
  }

  private async log(
    d: PushJobData,
    deviceTokenId: string | null,
    outcome: 'delivered' | 'failed',
    failureReason?: string,
  ): Promise<void> {
    const now = this.clock.now();
    await this.prisma.notificationLog.create({
      data: {
        userId: d.userId,
        deviceTokenId,
        kind: d.kind,
        priority: d.priority,
        title: d.title,
        body: d.body,
        deepLink: d.deepLink,
        projectId: d.projectId ?? null,
        payload: (d.payload ?? {}) as any,
        sentAt: now,
        deliveredAt: outcome === 'delivered' ? now : null,
        failedAt: outcome === 'failed' ? now : null,
        failureReason: outcome === 'failed' ? (failureReason ?? null) : null,
      },
    });

    // Если push принадлежит broadcast-кампании — инкрементируем deliveredCount
    // на BroadcastCampaign, чтобы admin видел корректные метрики (не всегда 0).
    // Считаем только успешные доставки — failed не учитывается в метрике.
    const broadcastId = d.payload?.broadcastId;
    if (outcome === 'delivered' && typeof broadcastId === 'string') {
      await this.prisma.broadcastCampaign
        .update({
          where: { id: broadcastId },
          data: { deliveredCount: { increment: 1 } },
        })
        .catch((e) => {
          // Кампания могла быть удалена — не блокируем основной flow.
          this.logger.warn(
            `failed to bump deliveredCount for broadcast ${broadcastId}: ${(e as Error).message}`,
          );
        });
    }
  }
}
