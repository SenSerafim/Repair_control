import { Injectable } from '@nestjs/common';
import { Prisma, ProjectStatus } from '@prisma/client';
import {
  Clock,
  ConflictError,
  ErrorCodes,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { FeedService } from '../feed/feed.service';

export interface CreateProjectInput {
  ownerId: string;
  title: string;
  address?: string;
  plannedStart?: string;
  plannedEnd?: string;
  workBudget?: number;
  materialsBudget?: number;
}

export interface UpdateProjectInput {
  title?: string;
  address?: string;
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
  ) {}

  async create(input: CreateProjectInput) {
    this.validateDateRange(input.plannedStart, input.plannedEnd);
    const project = await this.prisma.project.create({
      data: {
        ownerId: input.ownerId,
        title: input.title,
        address: input.address,
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
    return this.serialize(project);
  }

  async get(projectId: string) {
    const project = await this.prisma.project.findUnique({ where: { id: projectId } });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
    return this.serialize(project);
  }

  async listForUser(userId: string, status?: ProjectStatus) {
    const projects = await this.prisma.project.findMany({
      where: {
        status: status,
        OR: [{ ownerId: userId }, { memberships: { some: { userId } } }],
      },
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
