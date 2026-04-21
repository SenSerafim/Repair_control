import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { Prisma, Step } from '@prisma/client';
import {
  Clock,
  ConflictError,
  ErrorCodes,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { FeedService } from '../feed/feed.service';
import { ProgressCalculator } from '../stages/progress-calculator';
import { ApprovalsService } from '../approvals/approvals.service';

export interface CreateStepInput {
  stageId: string;
  title: string;
  type?: 'regular' | 'extra';
  price?: number;
  description?: string;
  orderIndex?: number;
  assigneeIds?: string[];
  actorUserId: string;
}

export interface UpdateStepInput {
  title?: string;
  price?: number;
  description?: string;
  assigneeIds?: string[];
  actorUserId: string;
}

@Injectable()
export class StepsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
    private readonly calc: ProgressCalculator,
    private readonly clock: Clock,
    @Inject(forwardRef(() => ApprovalsService))
    private readonly approvals: ApprovalsService,
  ) {}

  async create(input: CreateStepInput) {
    if (!input.title.trim()) {
      throw new InvalidInputError(ErrorCodes.STEP_TITLE_REQUIRED, 'title is required');
    }
    const type = input.type ?? 'regular';
    if (type === 'extra' && (input.price == null || input.price <= 0)) {
      throw new InvalidInputError(
        ErrorCodes.STEP_EXTRA_REQUIRES_PRICE,
        'extra work requires positive price',
      );
    }

    const stage = await this.prisma.stage.findUnique({
      where: { id: input.stageId },
      select: { id: true, projectId: true, status: true, project: { select: { ownerId: true } } },
    });
    if (!stage) throw new NotFoundError(ErrorCodes.STAGE_NOT_FOUND, 'stage not found');

    await this.validateAssignees(stage.projectId, input.assigneeIds);

    const count = await this.prisma.step.count({ where: { stageId: stage.id } });
    const orderIndex = input.orderIndex ?? count;
    const initialStatus: Step['status'] = type === 'extra' ? 'pending_approval' : 'pending';

    const step = await this.prisma.$transaction(async (tx) => {
      const s = await tx.step.create({
        data: {
          stageId: stage.id,
          title: input.title.trim(),
          orderIndex,
          type,
          status: initialStatus,
          price: input.price != null ? BigInt(input.price) : null,
          description: input.description,
          authorId: input.actorUserId,
          assigneeIds: input.assigneeIds ?? [],
        },
      });
      await this.feed.emit({
        tx,
        kind: type === 'extra' ? 'extra_work_requested' : 'step_created',
        projectId: stage.projectId,
        actorId: input.actorUserId,
        payload: { stageId: stage.id, stepId: s.id, title: s.title, type, price: input.price },
      });
      // Доп.работа сразу создаёт Approval scope=extra_work на заказчика (ТЗ §4.3, gaps §4.1)
      if (type === 'extra') {
        await this.approvals.request({
          scope: 'extra_work',
          projectId: stage.projectId,
          stageId: stage.id,
          stepId: s.id,
          addresseeId: stage.project.ownerId,
          payload: { stepId: s.id, price: input.price },
          requestedById: input.actorUserId,
          tx,
        });
      }
      // Пересчёт прогресса при добавлении шага в активный этап (gaps §2.3)
      if (this.isActiveStage(stage.status)) {
        await this.feed.emit({
          tx,
          kind: 'progress_recalculated_on_step_change',
          projectId: stage.projectId,
          actorId: input.actorUserId,
          payload: { stageId: stage.id, reason: 'step_created' },
        });
      }
      await this.calc.recalcStage(stage.id, tx);
      return s;
    });
    return this.serialize(step);
  }

  async get(stepId: string) {
    const step = await this.prisma.step.findUnique({
      where: { id: stepId },
      include: { substeps: { orderBy: { createdAt: 'asc' } }, photos: true },
    });
    if (!step) throw new NotFoundError(ErrorCodes.STEP_NOT_FOUND, 'step not found');
    return this.serialize(step);
  }

  async listForStage(stageId: string) {
    const steps = await this.prisma.step.findMany({
      where: { stageId },
      orderBy: { orderIndex: 'asc' },
      include: { substeps: { orderBy: { createdAt: 'asc' } }, photos: true },
    });
    return steps.map((s) => this.serialize(s));
  }

  async update(stepId: string, input: UpdateStepInput) {
    const existing = await this.prisma.step.findUnique({
      where: { id: stepId },
      include: { stage: { select: { projectId: true } } },
    });
    if (!existing) throw new NotFoundError(ErrorCodes.STEP_NOT_FOUND, 'step not found');
    await this.validateAssignees(existing.stage.projectId, input.assigneeIds);

    const data: Prisma.StepUpdateInput = {
      title: input.title,
      description: input.description,
      price: input.price !== undefined ? BigInt(input.price) : undefined,
      assigneeIds: input.assigneeIds,
    };
    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.step.update({ where: { id: stepId }, data });
      await this.feed.emit({
        tx,
        kind: 'step_updated',
        projectId: existing.stage.projectId,
        actorId: input.actorUserId,
        payload: { stageId: existing.stageId, stepId },
      });
      return u;
    });
    return this.serialize(updated);
  }

  async delete(stepId: string, actorUserId: string) {
    const existing = await this.prisma.step.findUnique({
      where: { id: stepId },
      include: { stage: { select: { projectId: true, status: true } } },
    });
    if (!existing) throw new NotFoundError(ErrorCodes.STEP_NOT_FOUND, 'step not found');

    await this.prisma.$transaction(async (tx) => {
      await tx.step.delete({ where: { id: stepId } });
      await this.feed.emit({
        tx,
        kind: 'step_deleted',
        projectId: existing.stage.projectId,
        actorId: actorUserId,
        payload: { stageId: existing.stageId, stepId },
      });
      if (this.isActiveStage(existing.stage.status)) {
        await this.feed.emit({
          tx,
          kind: 'progress_recalculated_on_step_change',
          projectId: existing.stage.projectId,
          actorId: actorUserId,
          payload: { stageId: existing.stageId, reason: 'step_deleted' },
        });
      }
      await this.calc.recalcStage(existing.stageId, tx);
    });
  }

  async reorder(stageId: string, items: { id: string; orderIndex: number }[], actorUserId: string) {
    const stage = await this.prisma.stage.findUnique({ where: { id: stageId } });
    if (!stage) throw new NotFoundError(ErrorCodes.STAGE_NOT_FOUND, 'stage not found');

    const steps = await this.prisma.step.findMany({
      where: { stageId },
      select: { id: true },
    });
    const known = new Set(steps.map((s) => s.id));
    for (const item of items) {
      if (!known.has(item.id)) {
        throw new InvalidInputError(
          ErrorCodes.STEP_REORDER_MISMATCH,
          `step ${item.id} does not belong to stage ${stageId}`,
        );
      }
    }

    await this.prisma.$transaction(async (tx) => {
      for (const item of items) {
        await tx.step.update({ where: { id: item.id }, data: { orderIndex: item.orderIndex } });
      }
      await this.feed.emit({
        tx,
        kind: 'steps_reordered',
        projectId: stage.projectId,
        actorId: actorUserId,
        payload: { stageId, items },
      });
    });
    return this.listForStage(stageId);
  }

  async complete(stepId: string, actorUserId: string) {
    const existing = await this.prisma.step.findUnique({
      where: { id: stepId },
      include: { stage: { select: { projectId: true, status: true } } },
    });
    if (!existing) throw new NotFoundError(ErrorCodes.STEP_NOT_FOUND, 'step not found');
    if (existing.status === 'done') {
      throw new ConflictError(ErrorCodes.STEP_INVALID_STATUS, 'step already done');
    }
    if (existing.status === 'pending_approval') {
      throw new ConflictError(
        ErrorCodes.STEP_INVALID_STATUS,
        'extra work requires approval before completion',
      );
    }

    const now = this.clock.now();
    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.step.update({
        where: { id: stepId },
        data: { status: 'done', doneAt: now, doneById: actorUserId },
      });
      await this.feed.emit({
        tx,
        kind: 'step_completed',
        projectId: existing.stage.projectId,
        actorId: actorUserId,
        payload: { stageId: existing.stageId, stepId },
      });
      await this.calc.recalcStage(existing.stageId, tx);
      return u;
    });
    return this.serialize(updated);
  }

  async uncomplete(stepId: string, actorUserId: string) {
    const existing = await this.prisma.step.findUnique({
      where: { id: stepId },
      include: { stage: { select: { projectId: true } } },
    });
    if (!existing) throw new NotFoundError(ErrorCodes.STEP_NOT_FOUND, 'step not found');
    if (existing.status !== 'done') {
      throw new ConflictError(ErrorCodes.STEP_INVALID_STATUS, 'step is not done');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.step.update({
        where: { id: stepId },
        data: { status: 'in_progress', doneAt: null, doneById: null },
      });
      await this.feed.emit({
        tx,
        kind: 'step_uncompleted',
        projectId: existing.stage.projectId,
        actorId: actorUserId,
        payload: { stageId: existing.stageId, stepId },
      });
      await this.calc.recalcStage(existing.stageId, tx);
      return u;
    });
    return this.serialize(updated);
  }

  private async validateAssignees(projectId: string, assigneeIds?: string[]) {
    if (!assigneeIds || assigneeIds.length === 0) return;
    const unique = Array.from(new Set(assigneeIds));
    const masters = await this.prisma.membership.findMany({
      where: { projectId, role: 'master', userId: { in: unique } },
      select: { userId: true },
    });
    const masterSet = new Set(masters.map((m) => m.userId));
    const invalid = unique.filter((id) => !masterSet.has(id));
    if (invalid.length > 0) {
      throw new InvalidInputError(
        ErrorCodes.STEP_INVALID_ASSIGNEE,
        `only master members can be assignees; invalid: ${invalid.join(',')}`,
      );
    }
  }

  private isActiveStage(status: string): boolean {
    return status === 'active' || status === 'paused' || status === 'review';
  }

  private serialize<T extends { price?: bigint | null }>(step: T) {
    return {
      ...step,
      price: step.price != null ? Number(step.price) : null,
    };
  }
}
