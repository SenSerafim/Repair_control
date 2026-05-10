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
  /// П2.14 — серийный/инвентарный номер. Свободный текст.
  serial?: string;
  /// П2.15 — инструмент сразу добавляется в проект (виден всем участникам).
  /// Если не задан — это инструмент только в личном профиле.
  projectId?: string;
}

export interface RequestToolInput {
  toolItemId: string;
  byUserId: string;
  /// Кол-во запрашиваемых единиц (default 1).
  qty?: number;
  /// Опц. этап, в рамках которого требуется инструмент.
  stageId?: string;
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
    // П2.14 / П8.1: создавать может ЛЮБОЙ пользователь — каждый только от своего имени.
    // Прежняя проверка «только contractor» снята по решению заказчика (раунд 1, 2026-05-03).
    const owner = await this.prisma.user.findUnique({ where: { id: input.ownerId } });
    if (!owner) throw new NotFoundError(ErrorCodes.TOOL_NOT_FOUND, 'owner not found');
    return this.prisma.toolItem.create({
      data: {
        ownerId: input.ownerId,
        name: input.name.trim(),
        totalQty: input.totalQty,
        unit: input.unit ?? 'шт',
        photoKey: input.photoKey,
        serial: input.serial,
        projectId: input.projectId ?? null,
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
    if (t.ownerId === actorUserId) return t;
    // QA-баг #11: tool из совместного проекта виден в реестре, но карточка
    // падала 403. Разрешаем read-доступ участникам проекта, к которому
    // привязан инструмент (write-операции остаются только у owner'а).
    if (t.projectId) {
      const membership = await this.prisma.membership.findFirst({
        where: { projectId: t.projectId, userId: actorUserId, removedAt: null },
        select: { id: true },
      });
      if (membership) return t;
    }
    throw new ForbiddenError(
      ErrorCodes.TOOL_ACCESS_DENIED,
      'only owner or project member can read',
    );
  }

  async deleteToolItem(id: string, actorUserId: string): Promise<void> {
    const tool = await this.prisma.toolItem.findUnique({ where: { id } });
    if (!tool) throw new NotFoundError(ErrorCodes.TOOL_NOT_FOUND, 'tool not found');
    if (tool.ownerId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.TOOL_ACCESS_DENIED, 'only owner can delete');
    }
    // Запрещаем удаление, пока есть незакрытые выдачи (всё, что не returned).
    const openIssuances = await this.prisma.toolIssuance.count({
      where: { toolItemId: id, status: { not: 'returned' } },
    });
    if (openIssuances > 0) {
      throw new ConflictError(
        ErrorCodes.TOOL_INSUFFICIENT_QTY,
        'cannot delete tool with active issuances; return them first',
      );
    }
    await this.prisma.toolItem.delete({ where: { id } });
  }

  /**
   * П2.15 — добавить уже существующий из «Моих инструментов» в проект.
   * Ставит ProjectId на ToolItem (видимость в реестре проекта). Bulk-вариант — на уровне controller.
   */
  async addToProject(
    toolItemId: string,
    projectId: string,
    actorUserId: string,
  ): Promise<ToolItem> {
    const tool = await this.prisma.toolItem.findUnique({ where: { id: toolItemId } });
    if (!tool) throw new NotFoundError(ErrorCodes.TOOL_NOT_FOUND, 'tool not found');
    if (tool.ownerId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.TOOL_ACCESS_DENIED, 'only owner can add to project');
    }
    return this.prisma.toolItem.update({ where: { id: toolItemId }, data: { projectId } });
  }

  /**
   * П2.15 — реестр инструментов проекта. Виден всем участникам проекта (прозрачность
   * «у кого сейчас находится»). Не путать с listIssuancesForProject (история выдач).
   */
  async listProjectRegistry(projectId: string): Promise<
    (ToolItem & {
      currentHolderId: string | null;
      hasActiveRequest: boolean;
    })[]
  > {
    const items = await this.prisma.toolItem.findMany({
      where: { projectId },
      include: {
        issuances: {
          orderBy: { createdAt: 'desc' },
          take: 5,
        },
      },
    });
    return items.map((t) => {
      const lastConfirmed = t.issuances.find((i) => i.status === 'confirmed');
      const activeRequest = t.issuances.find(
        (i) => i.status === 'requested' || i.status === 'approved',
      );
      return {
        ...t,
        currentHolderId: lastConfirmed?.toUserId ?? t.ownerId,
        hasActiveRequest: !!activeRequest,
      };
    });
  }

  // ---------- ToolIssuance ----------

  /**
   * П2.15 — заявка на получение инструмента: бригадир/мастер запрашивает у владельца.
   * Создаёт ToolIssuance(status=requested). Дальше владелец approve/reject.
   */
  async requestTool(input: RequestToolInput): Promise<ToolIssuance> {
    const tool = await this.prisma.toolItem.findUnique({ where: { id: input.toolItemId } });
    if (!tool) throw new NotFoundError(ErrorCodes.TOOL_NOT_FOUND, 'tool not found');
    if (!tool.projectId) {
      throw new InvalidInputError(
        ErrorCodes.TOOL_INSUFFICIENT_QTY,
        'tool is not attached to any project',
      );
    }
    if (tool.ownerId === input.byUserId) {
      throw new InvalidInputError(
        ErrorCodes.TOOL_ACCESS_DENIED,
        'cannot request your own tool — it is already yours',
      );
    }
    const qty = input.qty ?? 1;
    const available = tool.totalQty - tool.issuedQty;
    if (qty > available) {
      throw new ConflictError(
        ErrorCodes.TOOL_INSUFFICIENT_QTY,
        `requested ${qty}, available ${available}`,
      );
    }
    return this.prisma.$transaction(async (tx) => {
      const iss = await tx.toolIssuance.create({
        data: {
          toolItemId: tool.id,
          projectId: tool.projectId!,
          stageId: input.stageId ?? null,
          toUserId: input.byUserId,
          issuedById: tool.ownerId,
          qty,
          status: 'requested',
        },
      });
      await this.feed.emit({
        tx,
        kind: 'tool_requested',
        projectId: tool.projectId,
        actorId: input.byUserId,
        payload: {
          issuanceId: iss.id,
          toolId: tool.id,
          toolName: tool.name,
          addresseeId: tool.ownerId,
          requestedById: input.byUserId,
          qty,
        },
      });
      return iss;
    });
  }

  /**
   * П2.15 — владелец одобряет заявку. ToolIssuance: requested → approved.
   * После approved owner фактически передаёт инструмент (issued + далее confirmed).
   */
  async approveRequest(issuanceId: string, actorUserId: string): Promise<ToolIssuance> {
    const iss = await this.prisma.toolIssuance.findUnique({
      where: { id: issuanceId },
      include: { toolItem: true },
    });
    if (!iss) throw new NotFoundError(ErrorCodes.TOOL_ISSUANCE_NOT_FOUND, 'issuance not found');
    if (iss.toolItem.ownerId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.TOOL_ACCESS_DENIED, 'only owner can approve');
    }
    if (iss.status !== 'requested') {
      throw new ConflictError(
        ErrorCodes.TOOL_ISSUANCE_INVALID_STATUS,
        `cannot approve in status ${iss.status}`,
      );
    }
    const available = iss.toolItem.totalQty - iss.toolItem.issuedQty;
    if (iss.qty > available) {
      throw new ConflictError(
        ErrorCodes.TOOL_INSUFFICIENT_QTY,
        `requested ${iss.qty}, available ${available}`,
      );
    }
    return this.prisma.$transaction(async (tx) => {
      const u = await tx.toolIssuance.update({
        where: { id: issuanceId },
        data: { status: 'approved' },
      });
      await tx.toolItem.update({
        where: { id: iss.toolItemId },
        data: { issuedQty: { increment: iss.qty } },
      });
      await this.feed.emit({
        tx,
        kind: 'tool_request_approved',
        projectId: iss.projectId,
        actorId: actorUserId,
        payload: {
          issuanceId,
          toolId: iss.toolItemId,
          toolName: iss.toolItem.name,
          requestedById: iss.toUserId,
        },
      });
      return u;
    });
  }

  async rejectRequest(
    issuanceId: string,
    actorUserId: string,
    comment?: string,
  ): Promise<ToolIssuance> {
    const iss = await this.prisma.toolIssuance.findUnique({
      where: { id: issuanceId },
      include: { toolItem: true },
    });
    if (!iss) throw new NotFoundError(ErrorCodes.TOOL_ISSUANCE_NOT_FOUND, 'issuance not found');
    if (iss.toolItem.ownerId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.TOOL_ACCESS_DENIED, 'only owner can reject');
    }
    if (iss.status !== 'requested') {
      throw new ConflictError(
        ErrorCodes.TOOL_ISSUANCE_INVALID_STATUS,
        `cannot reject in status ${iss.status}`,
      );
    }
    return this.prisma.$transaction(async (tx) => {
      const u = await tx.toolIssuance.update({
        where: { id: issuanceId },
        data: { status: 'rejected' },
      });
      await this.feed.emit({
        tx,
        kind: 'tool_request_rejected',
        projectId: iss.projectId,
        actorId: actorUserId,
        payload: {
          issuanceId,
          toolId: iss.toolItemId,
          toolName: iss.toolItem.name,
          requestedById: iss.toUserId,
          comment,
        },
      });
      return u;
    });
  }

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
