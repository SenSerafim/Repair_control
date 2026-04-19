import { Injectable } from '@nestjs/common';
import { Prisma, Stage, StageStatus } from '@prisma/client';
import { Clock, PrismaService } from '@app/common';

export type SemaphoreColor = 'green' | 'yellow' | 'red' | 'blue' | 'done';

export interface StageSnapshot {
  id: string;
  status: StageStatus;
  plannedStart: Date | null;
  plannedEnd: Date | null;
  pauseDurationMs: bigint;
  startedAt: Date | null;
}

export interface StageSemaphoreResult {
  color: SemaphoreColor;
  reasons: string[];
}

/**
 * ProgressCalculator — расчёт прогресса (done/total) и цвета светофора (ТЗ §2.4).
 *
 * 5 веток:
 * - done — все этапы done
 * - blue — есть review (требуется действие заказчика) или rejected (требуется действие бригадира)
 * - red — есть просрочка: плановый конец < now или пауза > 3 дней или «дата старта прошла, Старт не нажат»
 * - yellow — ≤3 дня до дедлайна или недавняя пауза <3 дней
 * - green — штатная работа
 */
@Injectable()
export class ProgressCalculator {
  private static readonly LATE_THRESHOLD_MS = 3 * 24 * 60 * 60 * 1000;

  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
  ) {}

  stageSemaphore(stage: StageSnapshot, now: Date = this.clock.now()): StageSemaphoreResult {
    const reasons: string[] = [];
    if (stage.status === 'done') return { color: 'done', reasons: ['status=done'] };
    if (stage.status === 'review' || stage.status === 'rejected') {
      reasons.push(`status=${stage.status}`);
      return { color: 'blue', reasons };
    }

    // старт просрочен: плановый старт прошёл, но этап всё ещё pending
    if (
      stage.status === 'pending' &&
      stage.plannedStart &&
      stage.plannedStart.getTime() < now.getTime()
    ) {
      reasons.push('late_start');
      return { color: 'red', reasons };
    }

    // просрочка дедлайна с учётом пауз
    if (stage.plannedEnd) {
      const adjustedEnd = stage.plannedEnd.getTime() + Number(stage.pauseDurationMs);
      const msUntilEnd = adjustedEnd - now.getTime();
      if (msUntilEnd < 0) {
        reasons.push('overdue');
        return { color: 'red', reasons };
      }
      if (msUntilEnd <= ProgressCalculator.LATE_THRESHOLD_MS) {
        reasons.push('close_to_deadline');
        return { color: 'yellow', reasons };
      }
    }

    if (stage.status === 'paused') {
      reasons.push('paused');
      return { color: 'yellow', reasons };
    }

    return { color: 'green', reasons: ['on_track'] };
  }

  async recalcStage(stageId: string, tx?: Prisma.TransactionClient): Promise<void> {
    const client = tx ?? this.prisma;
    const stage = await client.stage.findUnique({ where: { id: stageId } });
    if (!stage) return;
    const progress =
      stage.status === 'done'
        ? 100
        : stage.status === 'review'
          ? 90
          : stage.status === 'active'
            ? 50
            : 0;
    await client.stage.update({
      where: { id: stageId },
      data: { progressCache: progress },
    });
    await this.recalcProject(stage.projectId, tx);
  }

  async recalcProject(projectId: string, tx?: Prisma.TransactionClient): Promise<void> {
    const client = tx ?? this.prisma;
    const stages = await client.stage.findMany({ where: { projectId } });
    const progress = this.computeProjectProgress(stages);
    const color = this.computeProjectSemaphore(stages);
    await client.project.update({
      where: { id: projectId },
      data: { progressCache: progress, semaphoreCache: color },
    });
  }

  computeProjectProgress(stages: Stage[]): number {
    if (stages.length === 0) return 0;
    const done = stages.filter((s) => s.status === 'done').length;
    return Math.round((done / stages.length) * 100);
  }

  computeProjectSemaphore(stages: Stage[]): SemaphoreColor {
    if (stages.length === 0) return 'green';
    if (stages.every((s) => s.status === 'done')) return 'done';
    const colors = stages.map((s) => this.stageSemaphore(s).color);
    if (colors.includes('red')) return 'red';
    if (colors.includes('blue')) return 'blue';
    if (colors.includes('yellow')) return 'yellow';
    return 'green';
  }
}
