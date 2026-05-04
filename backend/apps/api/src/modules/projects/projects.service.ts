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

export interface CreateProjectInput {
  ownerId: string;
  title: string;
  address?: string;
  description?: string;
  plannedStart?: string;
  plannedEnd?: string;
  workBudget?: number;
  materialsBudget?: number;
}

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
  ) {}

  async create(input: CreateProjectInput) {
    this.validateDateRange(input.plannedStart, input.plannedEnd);
    const project = await this.prisma.project.create({
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
    await this.feed.emit({
      kind: 'project_created',
      projectId: project.id,
      actorId: input.ownerId,
      payload: { title: project.title },
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
    return projects.map((p) => this.serialize(p));
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
          memberships: {
            create: {
              userId: source.ownerId,
              role: 'customer',
              permissions: {} as Prisma.InputJsonValue,
            },
          },
        },
      });
      for (const stage of source.stages) {
        await tx.stage.create({
          data: {
            projectId: p.id,
            title: stage.title,
            orderIndex: stage.orderIndex,
            plannedStart: stage.plannedStart,
            plannedEnd: stage.plannedEnd,
            originalEnd: stage.plannedEnd,
            workBudget: stage.workBudget,
            materialsBudget: stage.materialsBudget,
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
    return this.serialize(copy);
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
