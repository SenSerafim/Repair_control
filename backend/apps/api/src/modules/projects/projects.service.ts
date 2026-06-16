import * as crypto from 'crypto';
import { Injectable } from '@nestjs/common';
import { Prisma, ProjectStatus, SystemRole } from '@prisma/client';
import {
  Clock,
  ConflictError,
  ErrorCodes,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { FeedService } from '../feed/feed.service';
import { ChatsService } from '../chats/chats.service';
import { ProgressCalculator } from '../stages/progress-calculator';

export interface CreateProjectInput {
  ownerId: string;
  title: string;
  address?: string;
  description?: string;
  plannedStart?: string;
  plannedEnd?: string;
  workBudget?: number;
  materialsBudget?: number;
  /// П1.8 — список названий этапов для атомарного создания вместе с проектом.
  /// `undefined` (не передан) → создаются 3 дефолтных плейсхолдера. `[]` → ничего
  /// не создаётся (для API-клиентов, которые сами наполнят этапы потом).
  /// Любой непустой массив → создаются ровно эти этапы по порядку.
  initialStages?: string[];
}

/// Дефолтные этапы при создании проекта без передачи `initialStages`.
/// Минимальный универсальный каркас ремонта; пользователь переименует/удалит/
/// добавит позже на экране этапов. Принципиально 3 этапа, чтобы при первом
/// заходе уже было что показать и не было пустого экрана.
const DEFAULT_INITIAL_STAGES: ReadonlyArray<string> = ['Подготовка', 'Основные работы', 'Сдача'];

export interface UpdateProjectInput {
  title?: string;
  address?: string;
  description?: string;
  plannedStart?: string;
  plannedEnd?: string;
  workBudget?: number;
  materialsBudget?: number;
}

@Injectable()
export class ProjectsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
    private readonly clock: Clock,
    private readonly chats: ChatsService,
    private readonly calculator: ProgressCalculator,
  ) {}

  async create(input: CreateProjectInput) {
    this.validateDateRange(input.plannedStart, input.plannedEnd);
    // П1.8 — этапы при создании проекта.
    // `undefined` (не передан в DTO) → 3 дефолтных плейсхолдера, чтобы у
    //   пользователя при первом заходе было что показать. Источник UX: «всё
    //   просто, при создании этапы сразу есть».
    // `[]` → не создаём ничего (API-клиенты, копирование).
    // Любой непустой → создаём ровно эти, в одной транзакции с проектом —
    //   чтобы не было состояний «проект есть, этапов нет» при сетевых сбоях.
    const stageTitles = (
      input.initialStages === undefined ? [...DEFAULT_INITIAL_STAGES] : input.initialStages
    )
      .map((t) => t.trim())
      .filter((t) => t.length > 0);
    const project = await this.prisma.$transaction(async (tx) => {
      const p = await tx.project.create({
        data: {
          ownerId: input.ownerId,
          title: input.title,
          address: input.address,
          description: input.description,
          plannedStart: input.plannedStart ? new Date(input.plannedStart) : undefined,
          plannedEnd: input.plannedEnd ? new Date(input.plannedEnd) : undefined,
          workBudget: BigInt(input.workBudget ?? 0),
          materialsBudget: BigInt(input.materialsBudget ?? 0),
          memberships: {
            create: {
              userId: input.ownerId,
              role: 'customer',
              permissions: {} as Prisma.InputJsonValue,
            },
          },
        },
      });
      for (let i = 0; i < stageTitles.length; i++) {
        const s = await tx.stage.create({
          data: {
            projectId: p.id,
            title: stageTitles[i],
            orderIndex: i,
            workBudget: BigInt(0),
            materialsBudget: BigInt(0),
            foremanIds: [],
          },
        });
        await this.feed.emit({
          tx,
          kind: 'stage_created',
          projectId: p.id,
          actorId: input.ownerId,
          payload: { stageId: s.id, title: s.title, pendingApproval: false },
        });
      }
      return p;
    });
    await this.feed.emit({
      kind: 'project_created',
      projectId: project.id,
      actorId: input.ownerId,
      payload: { title: project.title, initialStages: stageTitles.length },
    });
    // П2.10 — общий project-chat создаётся сразу при создании проекта,
    // владелец автоматически становится первым участником. Все, кого добавят
    // в проект позже, попадают в чат через members.service.ts → addProjectChatParticipant.
    await this.chats.ensureProjectChat(project.id, input.ownerId);
    return this.serialize(project);
  }

  async get(projectId: string) {
    const project = await this.prisma.project.findUnique({ where: { id: projectId } });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
    return this.serialize(project);
  }

  /**
   * Каждая активная роль — изолированная «учётная запись» (см. UX-требование):
   * - customer → только проекты, где userId === ownerId.
   * - representative → проекты с membership(role='representative').
   * - contractor (бригадир) → проекты с membership(role='foreman').
   * - master → проекты с membership(role='master').
   * - admin → все (без фильтра).
   * Если activeRole не передан — fallback на legacy-поведение (owner ИЛИ любой membership).
   */
  async listForUser(userId: string, status?: ProjectStatus, activeRole?: SystemRole) {
    const where: Prisma.ProjectWhereInput = { status };

    // П2.16: фильтр membership.removedAt=null + hiddenForUser=false для всех ролей кроме owner-customer.
    const activeMembership = (
      role?: 'customer' | 'representative' | 'foreman' | 'master',
    ): Prisma.MembershipWhereInput => ({
      userId,
      role,
      removedAt: null,
      hiddenForUser: false,
    });

    switch (activeRole) {
      case 'customer':
        // owner-customer всегда видит свои проекты, hiddenForUser к нему не применяется
        where.ownerId = userId;
        break;
      case 'representative':
        where.memberships = { some: activeMembership('representative') };
        break;
      case 'contractor':
        where.memberships = { some: activeMembership('foreman') };
        break;
      case 'master':
        where.memberships = { some: activeMembership('master') };
        break;
      case 'admin':
        break;
      default:
        // Legacy / неизвестная роль — owner ИЛИ активный membership.
        where.OR = [{ ownerId: userId }, { memberships: { some: activeMembership() } }];
        break;
    }

    const projects = await this.prisma.project.findMany({
      where,
      orderBy: { updatedAt: 'desc' },
    });
    // NEWFIX §1 — мини-дашборд карточки проекта: бэк отдаёт счётчики
    // этапов (done / total / in_progress), чтобы клиент не делал N+1.
    // Одна батчевая выборка статусов этапов по всем найденным projectIds.
    const stageCounts = await this.aggregateStageCounts(projects.map((p) => p.id));
    return projects.map((p) => ({
      ...this.serialize(p),
      ...(stageCounts.get(p.id) ?? { stagesDone: 0, stagesTotal: 0, stagesInProgress: 0 }),
    }));
  }

  /**
   * Счёт по projectId: stagesTotal, stagesDone (status=done),
   * stagesInProgress (status ∈ {active, paused, review} — реально начатые,
   * кроме pending и кроме done).
   */
  private async aggregateStageCounts(
    projectIds: string[],
  ): Promise<Map<string, { stagesDone: number; stagesTotal: number; stagesInProgress: number }>> {
    const out = new Map<
      string,
      { stagesDone: number; stagesTotal: number; stagesInProgress: number }
    >();
    if (projectIds.length === 0) return out;
    const stages = await this.prisma.stage.findMany({
      where: { projectId: { in: projectIds } },
      select: { projectId: true, status: true },
    });
    for (const pid of projectIds) {
      out.set(pid, { stagesDone: 0, stagesTotal: 0, stagesInProgress: 0 });
    }
    for (const s of stages) {
      const c = out.get(s.projectId)!;
      c.stagesTotal += 1;
      if (s.status === 'done') c.stagesDone += 1;
      else if (s.status === 'active' || s.status === 'paused' || s.status === 'review') {
        c.stagesInProgress += 1;
      }
    }
    return out;
  }

  async update(projectId: string, input: UpdateProjectInput, actorUserId: string) {
    this.validateDateRange(input.plannedStart, input.plannedEnd);
    const existing = await this.prisma.project.findUnique({ where: { id: projectId } });
    if (!existing) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
    if (existing.status === 'archived') {
      throw new ConflictError(ErrorCodes.PROJECT_ARCHIVED, 'archived project is read-only');
    }
    const updated = await this.prisma.project.update({
      where: { id: projectId },
      data: {
        title: input.title,
        address: input.address,
        description: input.description,
        plannedStart: input.plannedStart ? new Date(input.plannedStart) : undefined,
        plannedEnd: input.plannedEnd ? new Date(input.plannedEnd) : undefined,
        workBudget: input.workBudget !== undefined ? BigInt(input.workBudget) : undefined,
        materialsBudget:
          input.materialsBudget !== undefined ? BigInt(input.materialsBudget) : undefined,
      },
    });
    await this.feed.emit({
      kind: 'project_created',
      projectId: updated.id,
      actorId: actorUserId,
      payload: { updated: true },
    });
    return this.serialize(updated);
  }

  async archive(projectId: string, actorUserId: string) {
    const project = await this.prisma.project.findUnique({ where: { id: projectId } });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
    if (project.status === 'archived') return this.serialize(project);
    const now = this.clock.now();
    const updated = await this.prisma.project.update({
      where: { id: projectId },
      data: { status: 'archived', archivedAt: now },
    });
    await this.feed.emit({
      kind: 'project_archived',
      projectId,
      actorId: actorUserId,
    });
    return this.serialize(updated);
  }

  async restore(projectId: string, actorUserId: string) {
    const project = await this.prisma.project.findUnique({ where: { id: projectId } });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
    const updated = await this.prisma.project.update({
      where: { id: projectId },
      data: { status: 'active', archivedAt: null },
    });
    await this.feed.emit({
      kind: 'project_restored',
      projectId,
      actorId: actorUserId,
    });
    return this.serialize(updated);
  }

  /**
   * П2.1 / 5.3 — изменение общего бюджета. Только заказчик. Без согласования.
   * Любое изменение фиксируется в feed (категория budget_changed_by_customer)
   * с прежним и новым значением + причиной (опц.). Это и есть «audit-log».
   */
  async updateBudget(
    projectId: string,
    actorUserId: string,
    input: { workBudget?: number; materialsBudget?: number; reason?: string },
  ) {
    const project = await this.prisma.project.findUnique({ where: { id: projectId } });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
    if (project.status === 'archived') {
      throw new ConflictError(ErrorCodes.PROJECT_ARCHIVED, 'archived project is read-only');
    }

    const prevWork = Number(project.workBudget);
    const prevMaterials = Number(project.materialsBudget);
    const nextWork = input.workBudget !== undefined ? input.workBudget : prevWork;
    const nextMaterials =
      input.materialsBudget !== undefined ? input.materialsBudget : prevMaterials;

    const updated = await this.prisma.project.update({
      where: { id: projectId },
      data: {
        workBudget: BigInt(nextWork),
        materialsBudget: BigInt(nextMaterials),
      },
    });

    await this.feed.emit({
      kind: 'budget_changed_by_customer',
      projectId,
      actorId: actorUserId,
      payload: {
        actor_role: 'customer',
        prev: { work: prevWork, materials: prevMaterials, total: prevWork + prevMaterials },
        next: { work: nextWork, materials: nextMaterials, total: nextWork + nextMaterials },
        reason: input.reason ?? null,
      },
    });

    return this.serialize(updated);
  }

  /**
   * П1.4 — список бригадиров проекта без фильтра по этапам (для picker аванса
   * и других сценариев назначения). Возвращает только активные membership.
   */
  async listForemen(projectId: string) {
    const memberships = await this.prisma.membership.findMany({
      where: { projectId, role: 'foreman', removedAt: null },
      select: {
        userId: true,
        user: {
          select: { id: true, firstName: true, lastName: true, phone: true, avatarUrl: true },
        },
      },
    });
    return memberships.map((m) => m.user);
  }

  /**
   * Копирование (ТЗ §4.3): копируются title, этапы, чек-листы, плановые бюджеты,
   * шаблоны/методички (ссылки). НЕ копируются: прогресс, выплаты, документы, подрядчики, лента.
   */
  async copy(projectId: string, actorUserId: string, newTitle?: string) {
    const source = await this.prisma.project.findUnique({
      where: { id: projectId },
      include: { stages: true },
    });
    if (!source) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'source not found');

    // QA-доку «Контроль ремонта.docx» баг #14: до этого фикса copy()
    // переносил только owner-membership и stages БЕЗ foremanIds/masterId.
    // Команда (members + бригадиры/мастера на этапах) и pending-инвайты
    // терялись — пользователь получал «копию» с одним собой и без работ
    // по этапам. Чиним полным переносом:
    //   1. memberships: все active (removedAt: null), с маппингом
    //      stageIds → новые stage ID после копирования этапов;
    //   2. stages: foremanIds/masterId копируем, фильтруя по
    //      переехавшим userId — на случай если в source были orphan-
    //      назначения после soft-remove;
    //   3. pending invitations: переносим с новым уникальным token,
    //      stageIds — также через map old→new.

    const sourceMemberships = await this.prisma.membership.findMany({
      where: { projectId, removedAt: null },
    });
    const copiedUserIds = new Set(sourceMemberships.map((m) => m.userId));
    // Owner customer-membership всегда есть, даже если в source он один.
    if (!copiedUserIds.has(source.ownerId)) {
      copiedUserIds.add(source.ownerId);
    }

    const sourcePendingInvitations = await this.prisma.projectInvitation.findMany({
      where: { projectId, status: 'pending' },
    });

    const copy = await this.prisma.$transaction(async (tx) => {
      const p = await tx.project.create({
        data: {
          ownerId: source.ownerId,
          title: newTitle ?? `${source.title} (копия)`,
          address: source.address,
          plannedStart: source.plannedStart,
          plannedEnd: source.plannedEnd,
          workBudget: source.workBudget,
          materialsBudget: source.materialsBudget,
        },
      });

      // 1a. Копируем memberships (включая owner-customer'а; если его нет
      // в source — это аномалия, но мы её закрываем создание явно).
      const ownerInSource = sourceMemberships.find(
        (m) => m.userId === source.ownerId && m.role === 'customer',
      );
      if (!ownerInSource) {
        await tx.membership.create({
          data: {
            projectId: p.id,
            userId: source.ownerId,
            role: 'customer',
            permissions: {} as Prisma.InputJsonValue,
          },
        });
      }
      for (const m of sourceMemberships) {
        await tx.membership.create({
          data: {
            projectId: p.id,
            userId: m.userId,
            role: m.role,
            invitedById: m.invitedById,
            // stageIds — позже обновим, когда узнаем new stage IDs.
            stageIds: [],
            permissions: (m.permissions ?? {}) as Prisma.InputJsonValue,
          },
        });
      }

      // 2. Stages с маппингом old → new + копированием foremanIds/masterId.
      const stageIdMap = new Map<string, string>();
      for (const stage of source.stages) {
        const sourceForemanIds = stage.foremanIds ?? [];
        const copiedForemanIds = sourceForemanIds.filter((id) => copiedUserIds.has(id));
        const copiedMasterId =
          stage.masterId && copiedUserIds.has(stage.masterId) ? stage.masterId : null;
        const newStage = await tx.stage.create({
          data: {
            projectId: p.id,
            title: stage.title,
            orderIndex: stage.orderIndex,
            plannedStart: stage.plannedStart,
            plannedEnd: stage.plannedEnd,
            originalEnd: stage.plannedEnd,
            workBudget: stage.workBudget,
            materialsBudget: stage.materialsBudget,
            foremanIds: copiedForemanIds,
            masterId: copiedMasterId,
          },
        });
        stageIdMap.set(stage.id, newStage.id);
      }

      // 1b. Обновляем stageIds в скопированных memberships по карте.
      for (const m of sourceMemberships) {
        if (m.stageIds.length === 0) continue;
        const newStageIds = m.stageIds
          .map((id) => stageIdMap.get(id))
          .filter((id): id is string => id !== undefined);
        if (newStageIds.length === 0) continue;
        await tx.membership.updateMany({
          where: { projectId: p.id, userId: m.userId },
          data: { stageIds: newStageIds },
        });
      }

      // 3. Pending invitations — переносим с новым уникальным token и
      // продлеваем expiresAt от текущего момента (TTL=14 дней,
      // унифицировано с invitations.service.ts).
      const newExpiresAt = new Date(this.clock.now().getTime() + 14 * 24 * 60 * 60 * 1000);
      for (const inv of sourcePendingInvitations) {
        const newStageIds = inv.stageIds
          .map((id) => stageIdMap.get(id))
          .filter((id): id is string => id !== undefined);
        await tx.projectInvitation.create({
          data: {
            projectId: p.id,
            phone: inv.phone,
            role: inv.role,
            invitedById: inv.invitedById,
            status: 'pending',
            token: generateInvitationToken(),
            permissions: (inv.permissions ?? {}) as Prisma.InputJsonValue,
            stageIds: newStageIds,
            expiresAt: newExpiresAt,
          },
        });
      }

      return p;
    });
    await this.feed.emit({
      kind: 'project_copied',
      projectId: copy.id,
      actorId: actorUserId,
      payload: { sourceProjectId: projectId },
    });
    // П2.10 — копия проекта тоже сразу получает общий чат с владельцем-customer.
    await this.chats.ensureProjectChat(copy.id, source.ownerId);
    // QA-баг #13 «При копировании проекта на главном экране отображается
    // неверный статус». Без пересчёта project.semaphoreCache остаётся в
    // дефолтном 'green' и не зависит от состояния скопированных стадий.
    // recalcProject пересчитывает progressCache + semaphoreCache по
    // фактическим plannedStart/plannedEnd/status стадий — это и есть
    // «правильный» цвет светофора для скопированного проекта.
    await this.calculator.recalcProject(copy.id);
    const refreshed = await this.prisma.project.findUnique({
      where: { id: copy.id },
    });
    return this.serialize(refreshed ?? copy);
  }

  private validateDateRange(start?: string, end?: string): void {
    if (start && end) {
      const s = new Date(start);
      const e = new Date(end);
      if (s.getTime() > e.getTime()) {
        throw new InvalidInputError('projects.invalid_dates', 'plannedStart must be <= plannedEnd');
      }
    }
  }

  private serialize<T extends { workBudget: bigint; materialsBudget: bigint }>(p: T) {
    return {
      ...p,
      workBudget: Number(p.workBudget),
      materialsBudget: Number(p.materialsBudget),
    };
  }
}

/// 6-значный numeric token для приглашений. Унифицирован с
/// invitations.service.ts#generateNumericCode, дублируется тут чтобы не
/// тащить инжект целого InvitationsService в copy()-flow.
function generateInvitationToken(): string {
  const min = 100_000;
  const max = 1_000_000;
  return crypto.randomInt(min, max).toString();
}
