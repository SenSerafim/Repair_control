import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '@app/common';
import { ProgressCalculator } from './progress-calculator';

/**
 * Каждые 15 минут проходит по активным проектам и пересчитывает светофор/прогресс.
 * Первичный пересчёт идёт на триггерах (старт/пауза/завершение этапа) — это подстраховка.
 */
@Injectable()
export class ProgressCronService {
  private readonly logger = new Logger(ProgressCronService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly calc: ProgressCalculator,
  ) {}

  @Cron('0 */15 * * * *')
  async tick(): Promise<void> {
    let projects: { id: string }[] = [];
    try {
      projects = await this.prisma.project.findMany({
        where: { status: 'active' },
        select: { id: true },
      });
    } catch (e) {
      this.logger.error('Failed to list active projects for recalc', e as Error);
      return;
    }
    for (const p of projects) {
      try {
        await this.calc.recalcProject(p.id);
      } catch (e) {
        this.logger.error(`Recalc failed for project ${p.id}`, e as Error);
      }
    }
  }
}
