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
  /// Системная роль actor'а (для решения, нужно ли создавать stage_create approval, П2.4).
  actorSystemRole?: 'customer' | 'representative' | 'contractor' | 'master' | 'admin';
}

export interface UpdateStageInput {
  title?: string;
  plannedStart?: string;
  plannedEnd?: string;
  workBudget?: number;
  materialsBudget?: number;
  foremanIds?: string[];
  /// П2.5 — назначенный мастер (один на этап).
  masterId?: string | null;
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

    // П2.4 — определить, нужен ли stage_create approval.
    // Бригадир (contractor membership=foreman) — создаёт через approval,
    // этап с плашкой «Ожидает согласования» (pendingApproval=true), шаги заблокированы.
    // Заказчик / представитель с canCreateStages — без approval.
    let needsApproval = false;
    if (
      input.actorSystemRole &&
      input.actorSystemRole !== 'customer' &&
      input.actorSystemRole !== 'admin'
    ) {
      const m = await this.prisma.membership.findFirst({
        where: { projectId: input.projectId, userId: input.actorUserId, removedAt: null },
        select: { role: true, permissions: true },
      });
      if (m?.role === 'foreman') {
        needsApproval = true;
      }
      if (m?.role === 'representative') {
        const perms = (m.permissions ?? {}) as Record<string, boolean | undefined>;
        // canCreateStages → как заказчик (без approval). Иначе — нет права создавать.
        needsApproval = !perms.canCreateStages;
      }
    }

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
          pendingApproval: needsApproval,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'stage_created',
        projectId: input.projectId,
        actorId: input.actorUserId,
        payload: { stageId: s.id, title: s.title, pendingApproval: needsApproval },
      });
      if (needsApproval) {
        // Сразу регистрируем approval. Адресат — заказчик.
        await this.approvals.request({
          scope: 'stage_create',
          projectId: input.projectId,
          stageId: s.id,
          addresseeId: project.ownerId,
          actorRole: 'customer',
          payload: { title: s.title, plannedStart: s.plannedStart, plannedEnd: s.plannedEnd },
          requestedById: input.actorUserId,
          tx,
        });
        await this.feed.emit({
          tx,
          kind: 'stage_pending_approval',
          projectId: input.projectId,
          actorId: input.actorUserId,
          payload: { stageId: s.id },
        });
      }
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

  /**
   * П1.11 / 4.8 — назначить единственного бригадира на этап. RBAC уже проверен в guard
   * (только заказчик / representative.canEditStages). Замена существующего — допустима.
   */
  async assignForeman(stageId: string, foremanUserId: string, actorUserId: string) {
    const stage = await this.prisma.stage.findUnique({ where: { id: stageId } });
    if (!stage) throw new NotFoundError(ErrorCodes.STAGE_NOT_FOUND, 'stage not found');

    // Проверяем, что user — действительно foreman в проекте.
    const m = await this.prisma.membership.findFirst({
      where: {
        projectId: stage.projectId,
        userId: foremanUserId,
        role: 'foreman',
        removedAt: null,
      },
    });
    if (!m) {
      throw new InvalidInputError(
        ErrorCodes.MEMBERSHIP_NOT_FOUND,
        'user is not an active foreman of this project',
      );
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.stage.update({
        where: { id: stageId },
        data: { foremanIds: [foremanUserId] },
      });
      await this.feed.emit({
        tx,
        kind: 'foreman_assigned',
        projectId: stage.projectId,
        actorId: actorUserId,
        payload: { stageId, foremanUserId },
      });
      return u;
    });
    try {
      await this.chats.ensureStageChat(stageId, actorUserId);
    } catch (e) {
      // silent
    }
    return this.serialize(updated);
  }

  /**
   * П2.5 / 7.5 — назначить мастера на этап (один). Назначает заказчик, представитель с правом
   * или бригадир этапа. Точная RBAC-проверка делается в контроллере/guard через stage.manage.
   */
  async assignMaster(stageId: string, masterUserId: string | null, actorUserId: string) {
    const stage = await this.prisma.stage.findUnique({ where: { id: stageId } });
    if (!stage) throw new NotFoundError(ErrorCodes.STAGE_NOT_FOUND, 'stage not found');

    if (masterUserId !== null) {
      const m = await this.prisma.membership.findFirst({
        where: {
          projectId: stage.projectId,
          userId: masterUserId,
          role: 'master',
          removedAt: null,
        },
      });
      if (!m) {
        throw new InvalidInputError(
          ErrorCodes.MEMBERSHIP_NOT_FOUND,
          'user is not an active master of this project',
        );
      }
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.stage.update({
        where: { id: stageId },
        data: { masterId: masterUserId },
      });
      await this.feed.emit({
        tx,
        kind: masterUserId ? 'master_assigned' : 'master_unassigned',
        projectId: stage.projectId,
        actorId: actorUserId,
        payload: { stageId, masterUserId },
      });
      return u;
    });
    return this.serialize(updated);
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
        foremanIds: true,
        planApproved: true,
        pendingApproval: true,
        project: { select: { requiresPlanApproval: true, planApproved: true } },
      },
    });
    // П2.4 — этап в pendingApproval (создан бригадиром, ждёт согласования заказчика)
    // не может стартовать.
    if (stage?.pendingApproval) {
      throw new ConflictError(
        'stage.pending_approval',
        'stage is awaiting customer approval (П2.4)',
      );
    }
    if (stage?.project.requiresPlanApproval && !stage.project.planApproved && !stage.planApproved) {
      throw new ConflictError(
        'approvals.plan_not_approved',
        'plan must be approved before starting this stage',
      );
    }
    // QA-доку «Контроль ремонта.docx» баг #1: запуск без бригадира должен
    // быть запрещён. До этого фикса foremanIds=[] не блокировал старт, а
    // UI-предупреждение «нельзя без бригадира» оставалось пустой
    // декларацией. По решению заказчика (П1.11) на этапе обязателен один
    // бригадир — без него старт не имеет смысла, потому что отвечать за
    // выполнение шагов некому. Кидаем валидируемую ошибку, чтобы клиент
    // мог показать понятное сообщение и переход к assign-foreman.
    if (stage && stage.foremanIds.length === 0) {
      throw new InvalidInputError(
        ErrorCodes.STAGE_NO_FOREMAN,
        'cannot start stage without an assigned foreman',
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

  /**
   * П2.3 / 4.2 — отправка плана этапа на согласование заказчику.
   *
   * Семантика «план этапа» (а не «план всего проекта», как было в legacy):
   * бригадир этапа описал, что и за какие сроки/деньги планирует делать,
   * и хочет фиксации до старта. Заказчик увидит approval scope=`plan` со
   * `stageId=X`, при approve бэкенд проставит `stage.planApproved=true`
   * (см. ApprovalsService.applyDecisionEffect → case 'plan'). После этого
   * `stage.start` уже не упирается в `approvals.plan_not_approved`.
   *
   * Кто может: бригадир (foreman этапа) или представитель с `canEditStages`.
   * Master отсекается на уровне ApprovalsService.validateRequest (scope=plan
   * запрещён для master, gaps §3.3).
   */
  async submitPlan(stageId: string, actorUserId: string) {
    const stage = await this.prisma.stage.findUnique({
      where: { id: stageId },
      select: {
        id: true,
        projectId: true,
        status: true,
        planApproved: true,
        pendingApproval: true,
        project: { select: { ownerId: true, status: true } },
      },
    });
    if (!stage) throw new NotFoundError(ErrorCodes.STAGE_NOT_FOUND, 'stage not found');
    if (stage.project.status === 'archived') {
      throw new ConflictError(ErrorCodes.PROJECT_ARCHIVED, 'archived project is read-only');
    }
    if (stage.pendingApproval) {
      throw new ConflictError(
        'stage.pending_approval',
        'stage itself awaits customer approval, cannot submit plan yet (П2.4)',
      );
    }
    if (stage.planApproved) {
      throw new ConflictError(
        'stage.plan_already_approved',
        'plan for this stage is already approved',
      );
    }
    // Если уже есть pending plan-approval для этого этапа — возвращаем его
    // (idempotent), чтобы повторный тап не плодил дубли.
    const existing = await this.prisma.approval.findFirst({
      where: {
        scope: 'plan',
        projectId: stage.projectId,
        stageId: stage.id,
        status: 'pending',
      },
      orderBy: { createdAt: 'desc' },
    });
    if (existing) return existing;
    return this.approvals.request({
      scope: 'plan',
      projectId: stage.projectId,
      stageId: stage.id,
      addresseeId: stage.project.ownerId,
      actorRole: 'customer',
      payload: { stageId: stage.id },
      requestedById: actorUserId,
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

      // П2.6 / 7.6 — двухступенчатый approval сдачи этапа.
      // Если actor — мастер этого этапа (есть masterId) → Approval#1 для бригадира.
      // Иначе (бригадир сдаёт сам, либо мастера нет) → сразу Approval#1 для заказчика.
      const project = await tx.project.findUnique({
        where: { id: stage.projectId },
        select: { ownerId: true },
      });
      if (!project) return;

      const isMasterSubmission = stage.masterId === actorUserId && stage.foremanIds.length > 0;
      if (isMasterSubmission) {
        const foremanId = stage.foremanIds[0];
        await this.approvals.request({
          scope: 'stage_accept',
          projectId: stage.projectId,
          stageId: stage.id,
          addresseeId: foremanId,
          actorRole: 'foreman',
          payload: { stageId: stage.id, step: 'foreman' },
          requestedById: actorUserId,
          tx,
        });
      } else {
        await this.approvals.request({
          scope: 'stage_accept',
          projectId: stage.projectId,
          stageId: stage.id,
          addresseeId: project.ownerId,
          actorRole: 'customer',
          payload: { stageId: stage.id, step: 'customer' },
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
