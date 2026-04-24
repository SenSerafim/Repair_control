import { Injectable } from '@nestjs/common';
import { PrismaService } from '@app/common';

@Injectable()
export class AdminOverviewService {
  constructor(private readonly prisma: PrismaService) {}

  async listDocuments(params: { projectId?: string; q?: string; limit: number; offset: number }) {
    const where: any = { deletedAt: null };
    if (params.projectId) where.projectId = params.projectId;
    if (params.q) {
      where.OR = [{ title: { contains: params.q, mode: 'insensitive' } }];
    }
    const [items, total] = await this.prisma.$transaction([
      this.prisma.document.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: Math.min(params.limit, 200),
        skip: params.offset,
        include: {
          project: { select: { id: true, title: true } },
        },
      }),
      this.prisma.document.count({ where }),
    ]);
    // Подтянем uploader'ов одним batch-запросом.
    const uploaderIds = [...new Set(items.map((d) => d.uploadedById))];
    const uploaders = uploaderIds.length
      ? await this.prisma.user.findMany({
          where: { id: { in: uploaderIds } },
          select: {
            id: true,
            phone: true,
            firstName: true,
            lastName: true,
          },
        })
      : [];
    const byId = Object.fromEntries(uploaders.map((u) => [u.id, u]));
    return {
      items: items.map((d) => ({ ...d, uploader: byId[d.uploadedById] ?? null })),
      total,
    };
  }

  async listPayments(params: {
    projectId?: string;
    status?: string;
    kind?: string;
    limit: number;
    offset: number;
  }) {
    const where: any = {};
    if (params.projectId) where.projectId = params.projectId;
    if (params.status) where.status = params.status;
    if (params.kind) where.kind = params.kind;
    const [items, total] = await this.prisma.$transaction([
      this.prisma.payment.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: Math.min(params.limit, 200),
        skip: params.offset,
        include: {
          project: { select: { id: true, title: true } },
        },
      }),
      this.prisma.payment.count({ where }),
    ]);
    const userIds = [...new Set(items.flatMap((p) => [p.fromUserId, p.toUserId]))];
    const users = userIds.length
      ? await this.prisma.user.findMany({
          where: { id: { in: userIds } },
          select: {
            id: true,
            phone: true,
            firstName: true,
            lastName: true,
          },
        })
      : [];
    const byId = Object.fromEntries(users.map((u) => [u.id, u]));
    return {
      items: items.map((p) => ({
        ...p,
        amount: p.amount.toString(),
        resolvedAmount: p.resolvedAmount?.toString() ?? null,
        from: byId[p.fromUserId] ?? null,
        to: byId[p.toUserId] ?? null,
      })),
      total,
    };
  }

  async listMaterials(params: {
    projectId?: string;
    status?: string;
    limit: number;
    offset: number;
  }) {
    const where: any = {};
    if (params.projectId) where.projectId = params.projectId;
    if (params.status) where.status = params.status;
    const [items, total] = await this.prisma.$transaction([
      this.prisma.materialRequest.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: Math.min(params.limit, 200),
        skip: params.offset,
        include: {
          project: { select: { id: true, title: true } },
          _count: { select: { items: true } },
        },
      }),
      this.prisma.materialRequest.count({ where }),
    ]);
    return { items, total };
  }

  async listApprovals(params: {
    projectId?: string;
    status?: string;
    scope?: string;
    limit: number;
    offset: number;
  }) {
    const where: any = {};
    if (params.projectId) where.projectId = params.projectId;
    if (params.status) where.status = params.status;
    if (params.scope) where.scope = params.scope;
    const [items, total] = await this.prisma.$transaction([
      this.prisma.approval.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: Math.min(params.limit, 200),
        skip: params.offset,
        include: {
          project: { select: { id: true, title: true } },
        },
      }),
      this.prisma.approval.count({ where }),
    ]);
    const userIds = [...new Set(items.flatMap((a) => [a.requestedById, a.addresseeId]))];
    const users = userIds.length
      ? await this.prisma.user.findMany({
          where: { id: { in: userIds } },
          select: { id: true, firstName: true, lastName: true },
        })
      : [];
    const byId = Object.fromEntries(users.map((u) => [u.id, u]));
    return {
      items: items.map((a) => ({
        ...a,
        requestedBy: byId[a.requestedById] ?? null,
        addressee: byId[a.addresseeId] ?? null,
      })),
      total,
    };
  }

  async listChats(params: { projectId?: string; type?: string; limit: number; offset: number }) {
    const where: any = {};
    if (params.projectId) where.projectId = params.projectId;
    if (params.type) where.type = params.type;
    const [items, total] = await this.prisma.$transaction([
      this.prisma.chat.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: Math.min(params.limit, 200),
        skip: params.offset,
        include: {
          project: { select: { id: true, title: true } },
          _count: { select: { messages: true, participants: true } },
        },
      }),
      this.prisma.chat.count({ where }),
    ]);
    return { items, total };
  }

  async listStages(params: { projectId?: string; status?: string; limit: number; offset: number }) {
    const where: any = {};
    if (params.projectId) where.projectId = params.projectId;
    if (params.status) where.status = params.status;
    const [items, total] = await this.prisma.$transaction([
      this.prisma.stage.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: Math.min(params.limit, 200),
        skip: params.offset,
        include: {
          project: { select: { id: true, title: true } },
          _count: { select: { steps: true } },
        },
      }),
      this.prisma.stage.count({ where }),
    ]);
    return { items, total };
  }

  async listUserSessions(userId: string) {
    return this.prisma.session.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        deviceId: true,
        userAgent: true,
        ipFingerprint: true,
        createdAt: true,
        expiresAt: true,
        revokedAt: true,
      },
    });
  }

  async listUserDevices(userId: string) {
    return this.prisma.deviceToken.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async listUserProjects(userId: string) {
    return this.prisma.membership.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: {
        project: {
          select: {
            id: true,
            title: true,
            status: true,
            semaphoreCache: true,
            progressCache: true,
            createdAt: true,
          },
        },
      },
    });
  }
}
