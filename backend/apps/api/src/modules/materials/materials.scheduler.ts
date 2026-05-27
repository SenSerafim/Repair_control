import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { Clock, PrismaService } from '@app/common';
import { FeedService } from '../feed/feed.service';

/**
 * MaterialsScheduler — ТЗ NEWFIX §5.5: «если дедлайн прошёл, а заявка не закрыта —
 * визуальный стикер "Просрочена" + уведомления».
 *
 * Каждые 15 минут ищем заявки в статусе `open` (= «Согласовано», ждёт доставки),
 * у которых хотя бы одна позиция имеет dueDate < now. Эмитим
 * `material_request_overdue` в feed (notification-router → push).
 *
 * Идемпотентность: за календарный день для одной заявки эмитим максимум одно
 * событие — фильтр по payload.requestId + createdAt >= startOfDay.
 */
@Injectable()
export class MaterialsScheduler {
  private readonly logger = new Logger(MaterialsScheduler.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly feed: FeedService,
  ) {}

  @Cron('0 */15 * * * *')
  async flagOverdueRequests(): Promise<void> {
    const now = this.clock.now();
    const startOfDay = new Date(now);
    startOfDay.setHours(0, 0, 0, 0);

    let candidates: Array<{
      id: string;
      projectId: string;
      stageId: string | null;
      title: string;
      items: Array<{ id: string; name: string; dueDate: Date | null }>;
    }> = [];
    try {
      candidates = await this.prisma.materialRequest.findMany({
        where: {
          status: 'open',
          items: { some: { dueDate: { lt: now } } },
        },
        select: {
          id: true,
          projectId: true,
          stageId: true,
          title: true,
          items: { select: { id: true, name: true, dueDate: true } },
        },
      });
    } catch (e) {
      this.logger.error('flagOverdueRequests: findMany failed', e as Error);
      return;
    }

    for (const r of candidates) {
      try {
        const alreadyEmitted = await this.prisma.feedEvent.findFirst({
          where: {
            projectId: r.projectId,
            kind: 'material_request_overdue',
            payload: { path: ['requestId'], equals: r.id },
            createdAt: { gte: startOfDay },
          },
          select: { id: true },
        });
        if (alreadyEmitted) continue;

        const overdueItems = r.items.filter((i) => i.dueDate && i.dueDate < now);
        if (overdueItems.length === 0) continue;

        await this.feed.emit({
          kind: 'material_request_overdue',
          projectId: r.projectId,
          stageId: r.stageId,
          actorId: null,
          payload: {
            requestId: r.id,
            title: r.title,
            overdueItemNames: overdueItems.map((i) => i.name),
            overdueItemCount: overdueItems.length,
          },
        });
        this.logger.log(`Заявка ${r.id} помечена просроченной (${overdueItems.length} поз.)`);
      } catch (e) {
        this.logger.error(`flagOverdueRequests: failed for ${r.id}`, e as Error);
      }
    }
  }
}
