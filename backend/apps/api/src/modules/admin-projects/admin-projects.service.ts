import { Injectable } from '@nestjs/common';
import { Prisma, ProjectStatus } from '@prisma/client';
import { Clock, NotFoundError, PrismaService } from '@app/common';
import { ErrorCodes } from '@app/common';
import { AdminAuditService } from '../admin-audit/admin-audit.service';

@Injectable()
export class AdminProjectsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly audit: AdminAuditService,
  ) {}

  async list(
    filters: {
      q?: string;
      status?: ProjectStatus;
      ownerId?: string;
      limit?: number;
      offset?: number;
    } = {},
  ) {
    const where: Prisma.ProjectWhereInput = {
      ...(filters.status ? { status: filters.status } : {}),
      ...(filters.ownerId ? { ownerId: filters.ownerId } : {}),
      ...(filters.q
        ? {
            OR: [
              { title: { contains: filters.q, mode: 'insensitive' } },
              { address: { contains: filters.q, mode: 'insensitive' } },
            ],
          }
        : {}),
    };
    const [items, total] = await this.prisma.$transaction([
      this.prisma.project.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: Math.min(filters.limit ?? 50, 200),
        skip: filters.offset ?? 0,
        include: {
          owner: { select: { id: true, phone: true, firstName: true, lastName: true } },
          _count: { select: { memberships: true, stages: true, payments: true, documents: true } },
        },
      }),
      this.prisma.project.count({ where }),
    ]);
    return { items, total };
  }

  async detail(projectId: string) {
    const p = await this.prisma.project.findUnique({
      where: { id: projectId },
      include: {
        owner: {
          select: { id: true, phone: true, firstName: true, lastName: true, activeRole: true },
        },
        memberships: {
          include: {
            user: { select: { id: true, phone: true, firstName: true, lastName: true } },
          },
        },
        stages: { orderBy: { orderIndex: 'asc' } },
        _count: {
          select: {
            payments: true,
            materialRequests: true,
            selfPurchases: true,
            chats: true,
            documents: true,
            exportJobs: true,
          },
        },
      },
    });
    if (!p) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
    return p;
  }

  async forceArchive(projectId: string, actorId: string, reason: string) {
    const p = await this.prisma.project.findUnique({ where: { id: projectId } });
    if (!p) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
    if (p.status === 'archived') return p;
    const updated = await this.prisma.project.update({
      where: { id: projectId },
      data: {
        status: 'archived',
        archivedAt: this.clock.now(),
      },
    });
    await this.audit.log({
      actorId,
      action: 'project.force_archive',
      targetType: 'Project',
      targetId: projectId,
      metadata: { reason },
    });
    return updated;
  }
}
