import { forwardRef, Inject, Injectable } from '@nestjs/common';
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
import { ApprovalsService } from '../approvals/approvals.service';
import { ChatsService } from '../chats/chats.service';

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
    @Inject(forwardRef(() => ApprovalsService))
    private readonly approvals: ApprovalsService,
    private readonly chats: ChatsService,
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

    // Автосоздание stage-чата если назначен хотя бы один foreman (ТЗ §10, §8 день 9).
    if ((input.foremanIds ?? []).length > 0) {
      try {
        await this.chats.ensureStageChat(stage.id, input.actorUserId);
      } catch (e) {
        // не ронять основной flow
      }
    }

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
    const existing = await this.prisma.stage.findUnique({ where: { id: stageId } });
    if (!existing) throw new NotFoundError(ErrorCodes.STAGE_NOT_FOUND, 'stage not found');
    // Валидируем интервал дат комбинацией новых и существующих значений (ТЗ §4.2).
    const effectiveStart = input.plannedStart
      ? input.plannedStart
      : existing.plannedStart
        ? existing.plannedStart.toISOString()
        : undefined;
    const effectiveEnd = input.plannedEnd
      ? input.plannedEnd
      : existing.plannedEnd
        ? existing.plannedEnd.toISOString()
        : undefined;
    this.validateDateRange(effectiveStart, effectiveEnd);

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

    // H.1: правка бюджета после старта (gaps §2.5) → emit stage_budget_edit_after_start
    const budgetChanged =
      (input.workBudget !== undefined && BigInt(input.workBudget) !== existing.workBudget) ||
      (input.materialsBudget !== undefined &&
        BigInt(input.materialsBudget) !== existing.materialsBudget);
    const postStart = existing.status !== 'pending';

    // H.2: diff foremanIds в активных этапах → пометить pending approvals requiresReassign
    const oldForemanIds = existing.foremanIds;
    const newForemanIds = input.foremanIds;
    const foremenChanged =
      newForemanIds !== undefined &&
      (newForemanIds.length !== oldForemanIds.length ||
        newForemanIds.some((id) => !oldForemanIds.includes(id)) ||
        oldForemanIds.some((id) => !newForemanIds.includes(id)));
    const removedForemen =
      foremenChanged && newForemanIds
        ? oldForemanIds.filter((id) => !newForemanIds.includes(id))
        : [];

    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.stage.update({ where: { id: stageId }, data });
      if (budgetChanged && postStart) {
        await this.feed.emit({
          tx,
          kind: 'stage_budget_edit_after_start',
          projectId: existing.projectId,
          actorId: input.actorUserId,
          payload: {
            stageId,
            oldWork: Number(existing.workBudget),
            newWork:
              input.workBudget !== undefined
                ? Number(input.workBudget)
                : Number(existing.workBudget),
            oldMaterials: Number(existing.materialsBudget),
            newMaterials:
              input.materialsBudget !== undefined
                ? Number(input.materialsBudget)
                : Number(existing.materialsBudget),
            notifyUserIds: existing.foremanIds,
          },
        });
      }
      if (foremenChanged && removedForemen.length > 0 && postStart) {
        // Помечаем открытые approvals на удалённых foremen как requiresReassign
        for (const removedId of removedForemen) {
          await tx.approval.updateMany({
            where: {
              stageId,
              addresseeId: removedId,
              status: 'pending',
            },
            data: { requiresReassign: true },
          });
        }
        await this.feed.emit({
          tx,
          kind: 'foreman_replaced',
          projectId: existing.projectId,
          actorId: input.actorUserId,
          payload: {
            stageId,
            removedForemen,
            addedForemen: newForemanIds!.filter((id) => !oldForemanIds.includes(id)),
          },
        });
      }
      return u;
    });

    await this.calc.recalcStage(stageId);

    // Автосоздание stage-чата, если в этапе теперь есть foreman (а раньше не было)
    if (newForemanIds && newForemanIds.length > 0 && oldForemanIds.length === 0) {
      try {
        await this.chats.ensureStageChat(stageId, input.actorUserId);
      } catch (e) {
        // silent
      }
    }

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
    // Гвард: план работ должен быть согласован, если проект этого требует (gaps §3.2)
    const stage = await this.prisma.stage.findUnique({
      where: { id: stageId },
      select: {
        planApproved: true,
        project: { select: { requiresPlanApproval: true, planApproved: true } },
      },
    });
    if (stage?.project.requiresPlanApproval && !stage.project.planApproved && !stage.planApproved) {
      throw new ConflictError(
        'approvals.plan_not_approved',
        'plan must be approved before starting this stage',
      );
    }
    return this.transition(stageId, actorUserId, 'start', async (st, tx) => {
      await tx.stage.update({
        where: { id: st.id },
        data: {
          status: 'active',
          startedAt: st.startedAt ?? this.clock.now(),
        },
      });
      await this.feed.emit({
        tx,
        kind: 'stage_started',
        projectId: st.projectId,
        actorId: actorUserId,
        payload: { stageId: st.id },
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
    // ТЗ §4.2 + дизайн c-pause-other: при reason='other' комментарий обязателен,
    // т.к. иначе заказчик не увидит причину паузы.
    if (reason === 'other' && !comment?.trim()) {
      throw new InvalidInputError(
        ErrorCodes.STAGE_PAUSE_COMMENT_REQUIRED,
        'comment is required when reason=other',
      );
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
      // ТЗ §2.4 / §4.4: запретить отправку этапа на приёмку, пока есть
      // незавершённые шаги. Без этого бригадир может «сдать» этап с 0%
      // прогресса, и заказчик получит pending-approval на пустую работу.
      const incomplete = await tx.step.count({
        where: { stageId: stage.id, status: { not: 'done' } },
      });
      if (incomplete > 0) {
        throw new InvalidInputError(
          ErrorCodes.STAGE_STEPS_INCOMPLETE,
          `Cannot send to review: ${incomplete} step(s) not completed`,
        );
      }
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
      // Создаём Approval scope=stage_accept, адресат — владелец проекта (ТЗ §4.4)
      const project = await tx.project.findUnique({
        where: { id: stage.projectId },
        select: { ownerId: true },
      });
      if (project) {
        await this.approvals.request({
          scope: 'stage_accept',
          projectId: stage.projectId,
          stageId: stage.id,
          addresseeId: project.ownerId,
          payload: { stageId: stage.id },
          requestedById: actorUserId,
          tx,
        });
      }
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
