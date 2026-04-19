import { Injectable } from '@nestjs/common';
import { Prisma, Stage } from '@prisma/client';
import {
  Clock,
  ConflictError,
  ErrorCodes,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { FeedService } from '../feed/feed.service';
import { StageLifecycle, StageTransition } from './stage-lifecycle';
import { ProgressCalculator } from './progress-calculator';

export interface CreateStageInput {
  projectId: string;
  title: string;
  orderIndex?: number;
  plannedStart?: string;
  plannedEnd?: string;
  workBudget?: number;
  materialsBudget?: number;
  foremanIds?: string[];
  actorUserId: string;
}

export interface UpdateStageInput {
  title?: string;
  plannedStart?: string;
  plannedEnd?: string;
  workBudget?: number;
  materialsBudget?: number;
  foremanIds?: string[];
  actorUserId: string;
}

@Injectable()
export class StagesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
    private readonly lifecycle: StageLifecycle,
    private readonly calc: ProgressCalculator,
    private readonly clock: Clock,
  ) {}

  async create(input: CreateStageInput) {
    const project = await this.prisma.project.findUnique({ where: { id: input.projectId } });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
    if (project.status === 'archived') {
      throw new ConflictError(ErrorCodes.PROJECT_ARCHIVED, 'archived project');
    }

    this.validateDateRange(input.plannedStart, input.plannedEnd);

    const count = await this.prisma.stage.count({ where: { projectId: input.projectId } });
    const orderIndex = input.orderIndex ?? count;

    const plannedEnd = input.plannedEnd ? new Date(input.plannedEnd) : null;
    const stage = await this.prisma.$transaction(async (tx) => {
      const s = await tx.stage.create({
        data: {
          projectId: input.projectId,
          title: input.title,
          orderIndex,
          plannedStart: input.plannedStart ? new Date(input.plannedStart) : null,
          plannedEnd,
          originalEnd: plannedEnd,
          workBudget: BigInt(input.workBudget ?? 0),
          materialsBudget: BigInt(input.materialsBudget ?? 0),
          foremanIds: input.foremanIds ?? [],
        },
      });
      await this.feed.emit({
        tx,
        kind: 'stage_created',
        projectId: input.projectId,
        actorId: input.actorUserId,
        payload: { stageId: s.id, title: s.title },
      });
      return s;
    });
    await this.maybeWarnStageOverProject(stage, project.plannedEnd, input.actorUserId);
    await this.calc.recalcProject(input.projectId);
    return this.serialize(stage);
  }

  async get(stageId: string) {
    const stage = await this.prisma.stage.findUnique({
      where: { id: stageId },
      include: { pauses: true },
    });
    if (!stage) throw new NotFoundError(ErrorCodes.STAGE_NOT_FOUND, 'stage not found');
    return this.serialize(stage);
  }

  async listForProject(projectId: string) {
    const stages = await this.prisma.stage.findMany({
      where: { projectId },
      orderBy: { orderIndex: 'asc' },
    });
    return stages.map((s) => this.serialize(s));
  }

  async update(stageId: string, input: UpdateStageInput) {
    this.validateDateRange(input.plannedStart, input.plannedEnd);
    const existing = await this.prisma.stage.findUnique({ where: { id: stageId } });
    if (!existing) throw new NotFoundError(ErrorCodes.STAGE_NOT_FOUND, 'stage not found');

    const data: Prisma.StageUpdateInput = {
      title: input.title,
      plannedStart: input.plannedStart ? new Date(input.plannedStart) : undefined,
      plannedEnd: input.plannedEnd ? new Date(input.plannedEnd) : undefined,
      workBudget: input.workBudget !== undefined ? BigInt(input.workBudget) : undefined,
      materialsBudget:
        input.materialsBudget !== undefined ? BigInt(input.materialsBudget) : undefined,
      foremanIds: input.foremanIds,
    };
    if (input.plannedEnd && !existing.originalEnd) {
      data.originalEnd = new Date(input.plannedEnd);
    }
    const updated = await this.prisma.stage.update({ where: { id: stageId }, data });
    await this.calc.recalcStage(stageId);
    return this.serialize(updated);
  }

  async reorder(
    projectId: string,
    items: { id: string; orderIndex: number }[],
    actorUserId: string,
  ) {
    const stages = await this.prisma.stage.findMany({ where: { projectId } });
    const known = new Set(stages.map((s) => s.id));
    for (const item of items) {
      if (!known.has(item.id)) {
        throw new InvalidInputError(ErrorCodes.STAGE_NOT_FOUND, `unknown stage: ${item.id}`);
      }
    }
    await this.prisma.$transaction(async (tx) => {
      for (const item of items) {
        await tx.stage.update({ where: { id: item.id }, data: { orderIndex: item.orderIndex } });
      }
      await this.feed.emit({
        tx,
        kind: 'stages_reordered',
        projectId,
        actorId: actorUserId,
        payload: { items },
      });
    });
    return this.listForProject(projectId);
  }

  async start(stageId: string, actorUserId: string) {
    return this.transition(stageId, actorUserId, 'start', async (stage, tx) => {
      await tx.stage.update({
        where: { id: stage.id },
        data: {
          status: 'active',
          startedAt: stage.startedAt ?? this.clock.now(),
        },
      });
      await this.feed.emit({
        tx,
        kind: 'stage_started',
        projectId: stage.projectId,
        actorId: actorUserId,
        payload: { stageId: stage.id },
      });
    });
  }

  async pause(
    stageId: string,
    actorUserId: string,
    reason: 'materials' | 'approval' | 'force_majeure' | 'other',
    comment?: string,
  ) {
    if (!reason) {
      throw new InvalidInputError(ErrorCodes.STAGE_PAUSE_REQUIRES_REASON, 'reason is required');
    }
    return this.transition(stageId, actorUserId, 'pause', async (stage, tx) => {
      await tx.pause.create({
        data: {
          stageId: stage.id,
          reason,
          comment,
          startedBy: actorUserId,
          startedAt: this.clock.now(),
        },
      });
      await tx.stage.update({
        where: { id: stage.id },
        data: { status: 'paused' },
      });
      await this.feed.emit({
        tx,
        kind: 'stage_paused',
        projectId: stage.projectId,
        actorId: actorUserId,
        payload: { stageId: stage.id, reason },
      });
    });
  }

  async resume(stageId: string, actorUserId: string) {
    return this.transition(stageId, actorUserId, 'resume', async (stage, tx) => {
      const openPause = await tx.pause.findFirst({
        where: { stageId: stage.id, endedAt: null },
        orderBy: { startedAt: 'desc' },
      });
      const now = this.clock.now();
      let addedMs = BigInt(0);
      if (openPause) {
        addedMs = BigInt(now.getTime() - openPause.startedAt.getTime());
        await tx.pause.update({
          where: { id: openPause.id },
          data: { endedAt: now },
        });
      }
      const newPauseTotal = stage.pauseDurationMs + addedMs;
      const newPlannedEnd = stage.originalEnd
        ? new Date(stage.originalEnd.getTime() + Number(newPauseTotal))
        : stage.plannedEnd;

      await tx.stage.update({
        where: { id: stage.id },
        data: {
          status: 'active',
          pauseDurationMs: newPauseTotal,
          plannedEnd: newPlannedEnd,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'stage_resumed',
        projectId: stage.projectId,
        actorId: actorUserId,
        payload: { stageId: stage.id, addedMs: Number(addedMs), newPlannedEnd },
      });
      await this.feed.emit({
        tx,
        kind: 'stage_deadline_recalculated',
        projectId: stage.projectId,
        actorId: actorUserId,
        payload: { stageId: stage.id, newPlannedEnd },
      });
    });
  }

  async sendToReview(stageId: string, actorUserId: string) {
    return this.transition(stageId, actorUserId, 'send_to_review', async (stage, tx) => {
      await tx.stage.update({
        where: { id: stage.id },
        data: { status: 'review', sentToReviewAt: this.clock.now() },
      });
      await this.feed.emit({
        tx,
        kind: 'stage_sent_to_review',
        projectId: stage.projectId,
        actorId: actorUserId,
        payload: { stageId: stage.id },
      });
    });
  }

  private async transition(
    stageId: string,
    actorUserId: string,
    action: StageTransition,
    apply: (stage: Stage, tx: Prisma.TransactionClient) => Promise<void>,
  ) {
    const stage = await this.prisma.stage.findUnique({ where: { id: stageId } });
    if (!stage) throw new NotFoundError(ErrorCodes.STAGE_NOT_FOUND, 'stage not found');
    // Валидируем переход; на этом этапе бросит InvalidInputError для запрещённых.
    this.lifecycle.nextStatus(stage.status, action);

    await this.prisma.$transaction(async (tx) => {
      await apply(stage, tx);
      await this.calc.recalcStage(stageId, tx);
    });

    const fresh = await this.prisma.stage.findUnique({ where: { id: stageId } });
    return this.serialize(fresh!);
  }

  private async maybeWarnStageOverProject(
    stage: Stage,
    projectPlannedEnd: Date | null,
    actorId: string,
  ) {
    if (!stage.plannedEnd || !projectPlannedEnd) return;
    if (stage.plannedEnd.getTime() > projectPlannedEnd.getTime()) {
      await this.feed.emit({
        kind: 'stage_deadline_exceeds_project',
        projectId: stage.projectId,
        actorId,
        payload: { stageId: stage.id, plannedEnd: stage.plannedEnd, projectPlannedEnd },
      });
    }
  }

  private validateDateRange(start?: string, end?: string) {
    if (start && end && new Date(start).getTime() > new Date(end).getTime()) {
      throw new InvalidInputError('stages.invalid_dates', 'plannedStart must be <= plannedEnd');
    }
  }

  private serialize<
    T extends { workBudget: bigint; materialsBudget: bigint; pauseDurationMs: bigint },
  >(s: T) {
    return {
      ...s,
      workBudget: Number(s.workBudget),
      materialsBudget: Number(s.materialsBudget),
      pauseDurationMs: Number(s.pauseDurationMs),
    };
  }
}
