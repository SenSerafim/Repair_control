import { Injectable } from '@nestjs/common';
import { MaterialRequest, Prisma } from '@prisma/client';
import {
  Clock,
  ConflictError,
  ErrorCodes,
  ForbiddenError,
  InvalidInputError,
  Money,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { FeedService } from '../feed/feed.service';

export interface CreateRequestInput {
  projectId: string;
  stageId?: string;
  recipient: 'foreman' | 'customer';
  title: string;
  comment?: string;
  items: Array<{
    name: string;
    qty: number;
    unit?: string;
    note?: string;
    pricePerUnit?: number;
  }>;
  actorUserId: string;
}

@Injectable()
export class MaterialsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
    private readonly clock: Clock,
  ) {}

  async createRequest(input: CreateRequestInput): Promise<MaterialRequest> {
    const project = await this.prisma.project.findUnique({
      where: { id: input.projectId },
      select: { id: true, status: true },
    });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
    if (project.status === 'archived') {
      throw new ConflictError(ErrorCodes.PROJECT_ARCHIVED, 'archived project');
    }

    if (input.items.length === 0) {
      throw new InvalidInputError(
        ErrorCodes.MATERIAL_INVALID_STATUS,
        'at least one item is required',
      );
    }

    const created = await this.prisma.$transaction(async (tx) => {
      const r = await tx.materialRequest.create({
        data: {
          projectId: project.id,
          stageId: input.stageId ?? null,
          createdById: input.actorUserId,
          recipient: input.recipient,
          title: input.title.trim(),
          comment: input.comment,
          status: 'draft',
          items: {
            create: input.items.map((it) => ({
              name: it.name.trim(),
              qty: new Prisma.Decimal(it.qty),
              unit: it.unit,
              note: it.note,
              pricePerUnit: it.pricePerUnit != null ? BigInt(it.pricePerUnit) : null,
              totalPrice:
                it.pricePerUnit != null ? BigInt(Math.round(it.pricePerUnit * it.qty)) : null,
            })),
          },
        },
        include: { items: true },
      });
      await this.feed.emit({
        tx,
        kind: 'material_request_created',
        projectId: project.id,
        actorId: input.actorUserId,
        payload: { requestId: r.id, stageId: input.stageId, recipient: input.recipient },
      });
      return r;
    });
    return created;
  }

  async get(id: string): Promise<MaterialRequest> {
    const r = await this.prisma.materialRequest.findUnique({
      where: { id },
      include: { items: true, disputes: true },
    });
    if (!r) throw new NotFoundError(ErrorCodes.MATERIAL_REQUEST_NOT_FOUND, 'request not found');
    return r;
  }

  async listForProject(
    projectId: string,
    filter?: { status?: string; stageId?: string },
  ): Promise<MaterialRequest[]> {
    const where: Prisma.MaterialRequestWhereInput = { projectId };
    if (filter?.status) where.status = filter.status as any;
    if (filter?.stageId) where.stageId = filter.stageId;
    return this.prisma.materialRequest.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: { items: true },
    });
  }

  async send(requestId: string, actorUserId: string): Promise<MaterialRequest> {
    const r = await this.prisma.materialRequest.findUnique({ where: { id: requestId } });
    if (!r) throw new NotFoundError(ErrorCodes.MATERIAL_REQUEST_NOT_FOUND, 'request not found');
    if (r.createdById !== actorUserId) {
      throw new ForbiddenError(
        ErrorCodes.MATERIAL_AUTHOR_ONLY_SEND,
        'only author can send request',
      );
    }
    if (r.status !== 'draft') {
      throw new ConflictError(ErrorCodes.MATERIAL_INVALID_STATUS, 'can send only draft requests');
    }
    return this.prisma.$transaction(async (tx) => {
      const u = await tx.materialRequest.update({
        where: { id: requestId },
        data: { status: 'open' },
      });
      await this.feed.emit({
        tx,
        kind: 'material_request_sent',
        projectId: r.projectId,
        actorId: actorUserId,
        payload: { requestId },
      });
      return u;
    });
  }

  async markItemBought(
    itemId: string,
    input: { pricePerUnit: number },
    actorUserId: string,
  ): Promise<MaterialRequest> {
    const item = await this.prisma.materialItem.findUnique({
      where: { id: itemId },
      include: {
        request: { include: { items: true, project: { select: { ownerId: true } } } },
      },
    });
    if (!item) throw new NotFoundError(ErrorCodes.MATERIAL_ITEM_NOT_FOUND, 'item not found');
    if (!['open', 'partially_bought'].includes(item.request.status)) {
      throw new ConflictError(
        ErrorCodes.MATERIAL_INVALID_STATUS,
        `cannot mark bought in status ${item.request.status}`,
      );
    }
    // Отмечает тот, кто исполнитель заявки: foreman (recipient=foreman) либо customer (recipient=customer)
    const actorOk =
      (item.request.recipient === 'customer' && item.request.project.ownerId === actorUserId) ||
      (item.request.recipient === 'foreman' &&
        (await this.isProjectForeman(item.request.projectId, actorUserId)));
    if (!actorOk) {
      throw new ForbiddenError(
        ErrorCodes.MATERIAL_CONFIRM_FORBIDDEN,
        'actor cannot mark bought for this request',
      );
    }

    const pricePerUnit = Money.ofKopeks(input.pricePerUnit).ensureNonNegative();
    const qtyNum = item.qty.toNumber();
    const totalPrice = Money.ofKopeks(Math.round(Number(pricePerUnit.kopeks()) * qtyNum));

    const now = this.clock.now();
    return this.prisma.$transaction(async (tx) => {
      await tx.materialItem.update({
        where: { id: itemId },
        data: {
          pricePerUnit: pricePerUnit.kopeks(),
          totalPrice: totalPrice.kopeks(),
          isBought: true,
          boughtAt: now,
        },
      });
      const allItems = await tx.materialItem.findMany({ where: { requestId: item.requestId } });
      const allBought = allItems.every((it) => it.isBought);
      const someBought = allItems.some((it) => it.isBought);
      const nextStatus = allBought
        ? 'bought'
        : someBought
          ? 'partially_bought'
          : item.request.status;
      await tx.materialRequest.update({
        where: { id: item.requestId },
        data: { status: nextStatus as any },
      });
      await this.feed.emit({
        tx,
        kind: 'material_item_bought',
        projectId: item.request.projectId,
        actorId: actorUserId,
        payload: { requestId: item.requestId, itemId },
      });
      return tx.materialRequest.findUnique({
        where: { id: item.requestId },
        include: { items: true },
      }) as unknown as MaterialRequest;
    });
  }

  async finalize(requestId: string, actorUserId: string): Promise<MaterialRequest> {
    const r = await this.prisma.materialRequest.findUnique({
      where: { id: requestId },
      include: { items: true },
    });
    if (!r) throw new NotFoundError(ErrorCodes.MATERIAL_REQUEST_NOT_FOUND, 'request not found');
    if (!['open', 'partially_bought', 'bought'].includes(r.status)) {
      throw new ConflictError(
        ErrorCodes.MATERIAL_FINALIZE_NOT_OPEN,
        `cannot finalize in status ${r.status}`,
      );
    }

    const now = this.clock.now();
    return this.prisma.$transaction(async (tx) => {
      const u = await tx.materialRequest.update({
        where: { id: requestId },
        data: { status: 'bought', finalizedAt: now },
      });
      await this.feed.emit({
        tx,
        kind: 'material_request_finalized',
        projectId: r.projectId,
        actorId: actorUserId,
        payload: { requestId },
      });
      await this.feed.emit({
        tx,
        kind: 'budget_updated',
        projectId: r.projectId,
        actorId: actorUserId,
        payload: { reason: 'material_finalized', requestId },
      });
      return u;
    });
  }

  async confirmDelivery(requestId: string, actorUserId: string): Promise<MaterialRequest> {
    const r = await this.prisma.materialRequest.findUnique({
      where: { id: requestId },
      include: { stage: true },
    });
    if (!r) throw new NotFoundError(ErrorCodes.MATERIAL_REQUEST_NOT_FOUND, 'request not found');
    if (!['bought', 'partially_bought'].includes(r.status) || !r.finalizedAt) {
      throw new ConflictError(
        ErrorCodes.MATERIAL_INVALID_STATUS,
        'delivery can be confirmed only for finalized requests',
      );
    }
    // Принимает: мастер стадии (если есть) или любой участник проекта (для общих материалов)
    if (r.stage && !r.stage.foremanIds.includes(actorUserId)) {
      // Проверим master через membership.stageIds
      const master = await this.prisma.membership.findFirst({
        where: {
          projectId: r.projectId,
          userId: actorUserId,
          role: 'master',
          stageIds: { has: r.stage.id },
        },
      });
      if (!master) {
        throw new ForbiddenError(
          ErrorCodes.MATERIAL_CONFIRM_FORBIDDEN,
          'only stage assignee can confirm delivery',
        );
      }
    }

    return this.prisma.$transaction(async (tx) => {
      const u = await tx.materialRequest.update({
        where: { id: requestId },
        data: { status: 'delivered', deliveredAt: this.clock.now(), deliveredById: actorUserId },
      });
      await this.feed.emit({
        tx,
        kind: 'material_delivered',
        projectId: r.projectId,
        actorId: actorUserId,
        payload: { requestId },
      });
      return u;
    });
  }

  async dispute(requestId: string, reason: string, actorUserId: string): Promise<MaterialRequest> {
    const r = await this.prisma.materialRequest.findUnique({ where: { id: requestId } });
    if (!r) throw new NotFoundError(ErrorCodes.MATERIAL_REQUEST_NOT_FOUND, 'request not found');
    if (!['bought', 'partially_bought', 'delivered'].includes(r.status)) {
      throw new ConflictError(
        ErrorCodes.MATERIAL_INVALID_STATUS,
        `cannot dispute in status ${r.status}`,
      );
    }
    return this.prisma.$transaction(async (tx) => {
      const u = await tx.materialRequest.update({
        where: { id: requestId },
        data: { status: 'disputed' },
      });
      await tx.materialDispute.create({
        data: { requestId, openedById: actorUserId, reason },
      });
      await this.feed.emit({
        tx,
        kind: 'material_disputed',
        projectId: r.projectId,
        actorId: actorUserId,
        payload: { requestId, reason },
      });
      return u;
    });
  }

  async resolve(
    requestId: string,
    input: { resolution: string; actorUserId: string },
  ): Promise<MaterialRequest> {
    const r = await this.prisma.materialRequest.findUnique({ where: { id: requestId } });
    if (!r) throw new NotFoundError(ErrorCodes.MATERIAL_REQUEST_NOT_FOUND, 'request not found');
    if (r.status !== 'disputed') {
      throw new ConflictError(
        ErrorCodes.MATERIAL_INVALID_STATUS,
        'can resolve only disputed requests',
      );
    }
    const now = this.clock.now();
    return this.prisma.$transaction(async (tx) => {
      const u = await tx.materialRequest.update({
        where: { id: requestId },
        data: { status: 'resolved' },
      });
      await tx.materialDispute.updateMany({
        where: { requestId, status: 'open' },
        data: {
          status: 'resolved',
          resolution: input.resolution,
          resolvedAt: now,
          resolvedBy: input.actorUserId,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'material_resolved',
        projectId: r.projectId,
        actorId: input.actorUserId,
        payload: { requestId },
      });
      return u;
    });
  }

  private async isProjectForeman(projectId: string, userId: string): Promise<boolean> {
    const m = await this.prisma.membership.findFirst({
      where: { projectId, userId, role: 'foreman' },
    });
    return !!m;
  }
}
