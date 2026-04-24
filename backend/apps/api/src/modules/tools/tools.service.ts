import { Injectable } from '@nestjs/common';
import { Prisma, ToolItem, ToolIssuance } from '@prisma/client';
import {
  Clock,
  ConflictError,
  ErrorCodes,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { FeedService } from '../feed/feed.service';

export interface CreateToolInput {
  ownerId: string;
  name: string;
  totalQty: number;
  unit?: string;
  photoKey?: string;
}

export interface IssueToolInput {
  toolItemId: string;
  projectId: string;
  stageId?: string;
  toUserId: string;
  qty: number;
  actorUserId: string;
}

@Injectable()
export class ToolsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
    private readonly clock: Clock,
  ) {}

  // ---------- ToolItem (профильные инструменты бригадира) ----------

  async createToolItem(input: CreateToolInput): Promise<ToolItem> {
    // Проверяем, что актёр имеет роль contractor (foreman)
    const owner = await this.prisma.user.findUnique({
      where: { id: input.ownerId },
      include: { roles: true },
    });
    if (!owner) throw new NotFoundError(ErrorCodes.TOOL_NOT_FOUND, 'owner not found');
    const hasContractorRole = owner.roles.some((r) => r.role === 'contractor' && r.isActive);
    if (!hasContractorRole) {
      throw new ForbiddenError(ErrorCodes.TOOL_OWNER_NOT_FOREMAN, 'only contractor can own tools');
    }
    return this.prisma.toolItem.create({
      data: {
        ownerId: input.ownerId,
        name: input.name.trim(),
        totalQty: input.totalQty,
        unit: input.unit ?? 'шт',
        photoKey: input.photoKey,
      },
    });
  }

  async updateToolItem(
    id: string,
    input: Partial<CreateToolInput>,
    actorUserId: string,
  ): Promise<ToolItem> {
    const existing = await this.prisma.toolItem.findUnique({ where: { id } });
    if (!existing) throw new NotFoundError(ErrorCodes.TOOL_NOT_FOUND, 'tool not found');
    if (existing.ownerId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.TOOL_ACCESS_DENIED, 'only owner can update');
    }
    if (input.totalQty != null && input.totalQty < existing.issuedQty) {
      throw new InvalidInputError(
        ErrorCodes.TOOL_INSUFFICIENT_QTY,
        `totalQty cannot be less than issuedQty (${existing.issuedQty})`,
      );
    }
    const data: Prisma.ToolItemUpdateInput = {
      name: input.name?.trim(),
      totalQty: input.totalQty,
      unit: input.unit,
      photoKey: input.photoKey,
    };
    return this.prisma.toolItem.update({ where: { id }, data });
  }

  async listOwn(ownerId: string): Promise<ToolItem[]> {
    return this.prisma.toolItem.findMany({
      where: { ownerId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getTool(id: string, actorUserId: string): Promise<ToolItem> {
    const t = await this.prisma.toolItem.findUnique({ where: { id } });
    if (!t) throw new NotFoundError(ErrorCodes.TOOL_NOT_FOUND, 'tool not found');
    if (t.ownerId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.TOOL_ACCESS_DENIED, 'only owner can read');
    }
    return t;
  }

  // ---------- ToolIssuance ----------

  async issue(input: IssueToolInput): Promise<ToolIssuance> {
    const tool = await this.prisma.toolItem.findUnique({ where: { id: input.toolItemId } });
    if (!tool) throw new NotFoundError(ErrorCodes.TOOL_NOT_FOUND, 'tool not found');
    if (tool.ownerId !== input.actorUserId) {
      throw new ForbiddenError(ErrorCodes.TOOL_ACCESS_DENIED, 'only owner can issue');
    }
    const available = tool.totalQty - tool.issuedQty;
    if (input.qty > available) {
      throw new ConflictError(
        ErrorCodes.TOOL_INSUFFICIENT_QTY,
        `requested ${input.qty}, available ${available}`,
      );
    }

    // Получатель — master этого проекта
    const master = await this.prisma.membership.findFirst({
      where: { projectId: input.projectId, userId: input.toUserId, role: 'master' },
    });
    if (!master) {
      throw new InvalidInputError(
        ErrorCodes.PAYMENT_INVALID_RECIPIENT,
        'recipient must be a master of the project',
      );
    }

    return this.prisma.$transaction(async (tx) => {
      const iss = await tx.toolIssuance.create({
        data: {
          toolItemId: tool.id,
          projectId: input.projectId,
          stageId: input.stageId ?? null,
          toUserId: input.toUserId,
          issuedById: input.actorUserId,
          qty: input.qty,
          status: 'issued',
        },
      });
      // issuedQty увеличивается сразу при issue (резервирование инструмента)
      await tx.toolItem.update({
        where: { id: tool.id },
        data: { issuedQty: { increment: input.qty } },
      });
      await this.feed.emit({
        tx,
        kind: 'tool_issued',
        projectId: input.projectId,
        actorId: input.actorUserId,
        payload: {
          issuanceId: iss.id,
          toolItemId: tool.id,
          toUserId: input.toUserId,
          qty: input.qty,
        },
      });
      return iss;
    });
  }

  async confirmReceipt(issuanceId: string, actorUserId: string): Promise<ToolIssuance> {
    const iss = await this.prisma.toolIssuance.findUnique({ where: { id: issuanceId } });
    if (!iss) throw new NotFoundError(ErrorCodes.TOOL_ISSUANCE_NOT_FOUND, 'issuance not found');
    if (iss.toUserId !== actorUserId) {
      throw new ForbiddenError(
        ErrorCodes.TOOL_CONFIRM_MASTER_ONLY,
        'only recipient can confirm receipt',
      );
    }
    if (iss.status !== 'issued') {
      throw new ConflictError(
        ErrorCodes.TOOL_ISSUANCE_INVALID_STATUS,
        `cannot confirm in status ${iss.status}`,
      );
    }
    return this.prisma.$transaction(async (tx) => {
      const u = await tx.toolIssuance.update({
        where: { id: issuanceId },
        data: { status: 'confirmed', confirmedAt: this.clock.now() },
      });
      await this.feed.emit({
        tx,
        kind: 'tool_issuance_confirmed',
        projectId: iss.projectId,
        actorId: actorUserId,
        payload: { issuanceId },
      });
      return u;
    });
  }

  async requestReturn(
    issuanceId: string,
    returnedQty: number,
    actorUserId: string,
  ): Promise<ToolIssuance> {
    const iss = await this.prisma.toolIssuance.findUnique({ where: { id: issuanceId } });
    if (!iss) throw new NotFoundError(ErrorCodes.TOOL_ISSUANCE_NOT_FOUND, 'issuance not found');
    if (iss.toUserId !== actorUserId) {
      throw new ForbiddenError(
        ErrorCodes.TOOL_RETURN_MASTER_ONLY,
        'only recipient can request return',
      );
    }
    if (iss.status !== 'confirmed') {
      throw new ConflictError(
        ErrorCodes.TOOL_ISSUANCE_INVALID_STATUS,
        `cannot return in status ${iss.status}`,
      );
    }
    if (returnedQty < 0 || returnedQty > iss.qty) {
      throw new InvalidInputError(
        ErrorCodes.TOOL_RETURN_QTY_INVALID,
        `returnedQty must be 0..${iss.qty}`,
      );
    }
    return this.prisma.$transaction(async (tx) => {
      const u = await tx.toolIssuance.update({
        where: { id: issuanceId },
        data: {
          status: 'return_requested',
          returnedQty,
          returnedAt: this.clock.now(),
        },
      });
      await this.feed.emit({
        tx,
        kind: 'tool_return_requested',
        projectId: iss.projectId,
        actorId: actorUserId,
        payload: { issuanceId, returnedQty },
      });
      return u;
    });
  }

  async confirmReturn(issuanceId: string, actorUserId: string): Promise<ToolIssuance> {
    const iss = await this.prisma.toolIssuance.findUnique({
      where: { id: issuanceId },
      include: { toolItem: true },
    });
    if (!iss) throw new NotFoundError(ErrorCodes.TOOL_ISSUANCE_NOT_FOUND, 'issuance not found');
    if (iss.toolItem.ownerId !== actorUserId) {
      throw new ForbiddenError(
        ErrorCodes.TOOL_RETURN_CONFIRM_OWNER_ONLY,
        'only tool owner can confirm return',
      );
    }
    if (iss.status !== 'return_requested') {
      throw new ConflictError(
        ErrorCodes.TOOL_ISSUANCE_INVALID_STATUS,
        `cannot confirm return in status ${iss.status}`,
      );
    }
    const returnedQty = iss.returnedQty ?? 0;
    return this.prisma.$transaction(async (tx) => {
      const u = await tx.toolIssuance.update({
        where: { id: issuanceId },
        data: { status: 'returned', returnConfirmedAt: this.clock.now() },
      });
      // issuedQty -= returnedQty (возвращаем инструмент в пул)
      await tx.toolItem.update({
        where: { id: iss.toolItemId },
        data: { issuedQty: { decrement: returnedQty } },
      });
      await this.feed.emit({
        tx,
        kind: 'tool_returned',
        projectId: iss.projectId,
        actorId: actorUserId,
        payload: { issuanceId, returnedQty, toolItemId: iss.toolItemId },
      });
      return u;
    });
  }

  async listIssuancesForProject(
    projectId: string,
    viewerUserId: string,
    viewerRole: 'customer' | 'representative' | 'foreman' | 'master' | undefined,
  ): Promise<ToolIssuance[]> {
    // Customer не видит инструмент (ТЗ §1.4)
    if (viewerRole === 'customer') {
      throw new ForbiddenError(ErrorCodes.TOOL_ACCESS_DENIED, 'customer cannot see tools');
    }
    const where: Prisma.ToolIssuanceWhereInput = { projectId };
    if (viewerRole === 'master') where.toUserId = viewerUserId;
    return this.prisma.toolIssuance.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: { toolItem: true },
    });
  }
}
