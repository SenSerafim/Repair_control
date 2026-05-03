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
  methodologyArticleId?: string | null;
  actorUserId: string;
}

export interface UpdateStepInput {
  title?: string;
  price?: number;
  description?: string;
  assigneeIds?: string[];
  methodologyArticleId?: string | null;
  /// П2.8 — отчёт о шаге («что/как делал»). Опционально.
  whatDid?: string | null;
  howDid?: string | null;
  actorUserId: string;
}

export interface CompleteStepInput {
  /// П2.8 — необязательные поля отчёта при закрытии шага.
  whatDid?: string;
  howDid?: string;
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

    if (input.methodologyArticleId) {
      const article = await this.prisma.methodologyArticle.findUnique({
        where: { id: input.methodologyArticleId },
        select: { id: true },
      });
      if (!article) {
        throw new InvalidInputError(
          ErrorCodes.STEP_METHODOLOGY_NOT_FOUND,
          'methodology article not found',
        );
      }
    }

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
          methodologyArticleId: input.methodologyArticleId ?? null,
        },
      });
      await this.feed.emit({
        tx,
        kind: type === 'extra' ? 'extra_work_requested' : 'step_created',
        projectId: stage.projectId,
        actorId: input.actorUserId,
        payload: { stageId: stage.id, stepId: s.id, title: s.title, type, price: input.price },
      });
      // П2.3 / 4.3 — доп.работа создаёт Approval с двухступенчатой цепочкой:
      //   мастер → бригадир → заказчик (Approval#2 эмитится в applyDecisionEffect)
      //   бригадир → сразу заказчик
      // Никаких auto-approve. Списание из бюджета — только финальный approve customer.
      if (type === 'extra') {
        const requesterMembership = await tx.membership.findFirst({
          where: { projectId: stage.projectId, userId: input.actorUserId, removedAt: null },
          select: { role: true },
        });
        const requesterIsMaster = requesterMembership?.role === 'master';
        if (requesterIsMaster) {
          // Найти бригадира этапа (если есть). Иначе — fallback: customer (нет цепочки).
          const stageWithForemen = await tx.stage.findUnique({
            where: { id: stage.id },
            select: { foremanIds: true },
          });
          const foremanId = stageWithForemen?.foremanIds?.[0];
          if (foremanId) {
            await this.approvals.request({
              scope: 'extra_work',
              projectId: stage.projectId,
              stageId: stage.id,
              stepId: s.id,
              addresseeId: foremanId,
              actorRole: 'foreman',
              payload: { stepId: s.id, price: input.price, step: 'foreman' },
              requestedById: input.actorUserId,
              tx,
            });
          } else {
            // Нет бригадира — заявка идёт сразу заказчику (как fallback).
            await this.approvals.request({
              scope: 'extra_work',
              projectId: stage.projectId,
              stageId: stage.id,
              stepId: s.id,
              addresseeId: stage.project.ownerId,
              actorRole: 'customer',
              payload: { stepId: s.id, price: input.price, step: 'customer' },
              requestedById: input.actorUserId,
              tx,
            });
          }
        } else {
          // Бригадир / иной — сразу к заказчику.
          await this.approvals.request({
            scope: 'extra_work',
            projectId: stage.projectId,
            stageId: stage.id,
            stepId: s.id,
            addresseeId: stage.project.ownerId,
            actorRole: 'customer',
            payload: { stepId: s.id, price: input.price, step: 'customer' },
            requestedById: input.actorUserId,
            tx,
          });
        }
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

    if (input.methodologyArticleId) {
      const article = await this.prisma.methodologyArticle.findUnique({
        where: { id: input.methodologyArticleId },
        select: { id: true },
      });
      if (!article) {
        throw new InvalidInputError(
          ErrorCodes.STEP_METHODOLOGY_NOT_FOUND,
          'methodology article not found',
        );
      }
    }

    const data: Prisma.StepUpdateInput = {
      title: input.title,
      description: input.description,
      price: input.price !== undefined ? BigInt(input.price) : undefined,
      assigneeIds: input.assigneeIds,
      // П2.8
      whatDid: input.whatDid !== undefined ? input.whatDid : undefined,
      howDid: input.howDid !== undefined ? input.howDid : undefined,
    };
    if (input.methodologyArticleId !== undefined) {
      // null чистит, string — устанавливает
      (data as { methodologyArticleId?: string | null }).methodologyArticleId =
        input.methodologyArticleId;
    }
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

  async complete(stepId: string, input: CompleteStepInput | string) {
    // Backward-compat: раньше второй аргумент был просто actorUserId.
    const actorUserId = typeof input === 'string' ? input : input.actorUserId;
    const whatDid = typeof input === 'string' ? undefined : input.whatDid;
    const howDid = typeof input === 'string' ? undefined : input.howDid;

    const existing = await this.prisma.step.findUnique({
      where: { id: stepId },
      include: { stage: { select: { projectId: true, status: true, pendingApproval: true } } },
    });
    if (!existing) throw new NotFoundError(ErrorCodes.STEP_NOT_FOUND, 'step not found');
    // П2.4 — нельзя закрывать шаг этапа, который ждёт согласования (pendingApproval).
    if (existing.stage.pendingApproval) {
      throw new ConflictError(
        'stage.pending_approval',
        'cannot complete step: stage awaits customer approval (П2.4)',
      );
    }
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
        data: {
          status: 'done',
          doneAt: now,
          doneById: actorUserId,
          // П2.8 — фиксируем отчёт мастера/бригадира при закрытии шага.
          whatDid: whatDid ?? undefined,
          howDid: howDid ?? undefined,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'step_completed',
        projectId: existing.stage.projectId,
        actorId: actorUserId,
        payload: {
          stageId: existing.stageId,
          stepId,
          hasReport: !!(whatDid || howDid),
        },
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
