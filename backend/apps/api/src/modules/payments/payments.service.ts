import { Injectable } from '@nestjs/common';
import { Payment, PaymentKind, PaymentStatus, Prisma } from '@prisma/client';
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

export interface CreateAdvanceInput {
  projectId: string;
  toUserId: string;
  amount: number;
  stageId?: string;
  comment?: string;
  photoKey?: string;
  actorUserId: string;
  idempotencyKey?: string;
}

export interface DistributeInput {
  parentPaymentId: string;
  toUserId: string;
  amount: number;
  stageId?: string;
  comment?: string;
  photoKey?: string;
  actorUserId: string;
  idempotencyKey?: string;
}

@Injectable()
export class PaymentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
    private readonly clock: Clock,
  ) {}

  async createAdvance(input: CreateAdvanceInput): Promise<Payment> {
    const amount = Money.ofKopeks(input.amount).ensurePositive(ErrorCodes.PAYMENT_AMOUNT_INVALID);

    const project = await this.prisma.project.findUnique({
      where: { id: input.projectId },
      select: { id: true, ownerId: true, status: true },
    });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
    if (project.status === 'archived') {
      throw new ConflictError(ErrorCodes.PROJECT_ARCHIVED, 'archived project');
    }

    // Получатель аванса — участник проекта с ролью foreman
    const foreman = await this.prisma.membership.findFirst({
      where: { projectId: project.id, userId: input.toUserId, role: 'foreman' },
    });
    if (!foreman) {
      throw new InvalidInputError(
        ErrorCodes.PAYMENT_INVALID_RECIPIENT,
        'recipient must be a foreman of the project',
      );
    }

    const created = await this.prisma.$transaction(async (tx) => {
      const p = await tx.payment.create({
        data: {
          projectId: project.id,
          stageId: input.stageId ?? null,
          kind: 'advance',
          fromUserId: input.actorUserId,
          toUserId: input.toUserId,
          amount: amount.kopeks(),
          comment: input.comment,
          photoKey: input.photoKey,
          status: 'pending',
          idempotencyKey: input.idempotencyKey ?? null,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'payment_created',
        projectId: project.id,
        actorId: input.actorUserId,
        payload: {
          paymentId: p.id,
          kind: 'advance',
          toUserId: input.toUserId,
          amount: Number(amount.kopeks()),
        },
      });
      return p;
    });
    return this.serialize(created);
  }

  async createDistribution(
    input: DistributeInput,
  ): Promise<Payment & { warning?: 'exceeds_parent_remaining' }> {
    const amount = Money.ofKopeks(input.amount).ensurePositive(ErrorCodes.PAYMENT_AMOUNT_INVALID);

    const parent = await this.prisma.payment.findUnique({
      where: { id: input.parentPaymentId },
      include: { children: true },
    });
    if (!parent) throw new NotFoundError(ErrorCodes.PAYMENT_NOT_FOUND, 'parent payment not found');
    if (parent.kind !== 'advance') {
      throw new ConflictError(
        ErrorCodes.PAYMENT_INVALID_STATUS,
        'distribution requires advance parent',
      );
    }
    if (parent.status !== 'confirmed' && parent.status !== 'resolved') {
      throw new ConflictError(
        ErrorCodes.PAYMENT_PARENT_NOT_CONFIRMED,
        'parent advance must be confirmed before distribution',
      );
    }
    // Распределять может только получатель исходного аванса (foreman = parent.toUserId)
    if (parent.toUserId !== input.actorUserId) {
      throw new ForbiddenError(
        ErrorCodes.PAYMENT_DISTRIBUTE_FORBIDDEN,
        'only parent recipient can distribute',
      );
    }

    // Получатель — master проекта
    const master = await this.prisma.membership.findFirst({
      where: { projectId: parent.projectId, userId: input.toUserId, role: 'master' },
    });
    if (!master) {
      throw new InvalidInputError(
        ErrorCodes.PAYMENT_INVALID_RECIPIENT,
        'recipient must be a master of the project',
      );
    }

    // Warning gaps §4.2: если sum(active children) + amount > parent.amount → warning, НЕ блок
    const parentAmount = Money.ofKopeks(parent.resolvedAmount ?? parent.amount);
    const activeChildrenSum = parent.children
      .filter((c) => c.status !== 'cancelled')
      .reduce((acc, c) => acc.plus(Money.ofKopeks(c.resolvedAmount ?? c.amount)), Money.zero());
    const projectedTotal = activeChildrenSum.plus(amount);
    const warning = projectedTotal.greaterThan(parentAmount)
      ? 'exceeds_parent_remaining'
      : undefined;

    const created = await this.prisma.$transaction(async (tx) => {
      const p = await tx.payment.create({
        data: {
          projectId: parent.projectId,
          stageId: input.stageId ?? parent.stageId ?? null,
          parentPaymentId: parent.id,
          kind: 'distribution',
          fromUserId: input.actorUserId,
          toUserId: input.toUserId,
          amount: amount.kopeks(),
          comment: input.comment,
          photoKey: input.photoKey,
          status: 'pending',
          idempotencyKey: input.idempotencyKey ?? null,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'payment_distributed',
        projectId: parent.projectId,
        actorId: input.actorUserId,
        payload: {
          paymentId: p.id,
          parentPaymentId: parent.id,
          toUserId: input.toUserId,
          amount: Number(amount.kopeks()),
          warning,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'payment_created',
        projectId: parent.projectId,
        actorId: input.actorUserId,
        payload: { paymentId: p.id, kind: 'distribution' },
      });
      return p;
    });
    return { ...this.serialize(created), warning };
  }

  async confirm(paymentId: string, actorUserId: string): Promise<Payment> {
    const payment = await this.prisma.payment.findUnique({ where: { id: paymentId } });
    if (!payment) throw new NotFoundError(ErrorCodes.PAYMENT_NOT_FOUND, 'payment not found');
    if (payment.toUserId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.PAYMENT_CONFIRM_FORBIDDEN, 'only recipient can confirm');
    }
    if (payment.status !== 'pending') {
      throw new ConflictError(
        ErrorCodes.PAYMENT_NOT_PENDING,
        `payment is ${payment.status}, cannot confirm`,
      );
    }

    const now = this.clock.now();
    const updated = await this.prisma.$transaction(async (tx) => {
      // Атомарный переход — защита от гонки: меняем только если всё ещё pending
      const affected = await tx.payment.updateMany({
        where: { id: paymentId, status: 'pending' },
        data: { status: 'confirmed', confirmedAt: now },
      });
      if (affected.count === 0) {
        throw new ConflictError(ErrorCodes.PAYMENT_NOT_PENDING, 'payment was already processed');
      }
      const fresh = await tx.payment.findUnique({ where: { id: paymentId } });
      await this.feed.emit({
        tx,
        kind: 'payment_confirmed',
        projectId: payment.projectId,
        actorId: actorUserId,
        payload: { paymentId, amount: Number(payment.amount), toUserId: payment.toUserId },
      });
      await this.feed.emit({
        tx,
        kind: 'budget_updated',
        projectId: payment.projectId,
        actorId: actorUserId,
        payload: { reason: 'payment_confirmed', paymentId },
      });
      return fresh!;
    });
    return this.serialize(updated);
  }

  async cancel(paymentId: string, actorUserId: string): Promise<Payment> {
    const payment = await this.prisma.payment.findUnique({ where: { id: paymentId } });
    if (!payment) throw new NotFoundError(ErrorCodes.PAYMENT_NOT_FOUND, 'payment not found');
    if (payment.fromUserId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.PAYMENT_CANCEL_FORBIDDEN, 'only sender can cancel');
    }
    if (payment.status !== 'pending') {
      throw new ConflictError(
        ErrorCodes.PAYMENT_NOT_PENDING,
        'only pending payments can be cancelled',
      );
    }
    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.payment.update({
        where: { id: paymentId },
        data: { status: 'cancelled', cancelledAt: this.clock.now() },
      });
      await this.feed.emit({
        tx,
        kind: 'payment_cancelled',
        projectId: payment.projectId,
        actorId: actorUserId,
        payload: { paymentId },
      });
      return u;
    });
    return this.serialize(updated);
  }

  async dispute(
    paymentId: string,
    reason: string,
    actorUserId: string,
    photoKeys: string[] = [],
  ): Promise<Payment> {
    const payment = await this.prisma.payment.findUnique({ where: { id: paymentId } });
    if (!payment) throw new NotFoundError(ErrorCodes.PAYMENT_NOT_FOUND, 'payment not found');
    if (payment.fromUserId !== actorUserId && payment.toUserId !== actorUserId) {
      throw new ForbiddenError(
        ErrorCodes.PAYMENT_DISPUTE_FORBIDDEN,
        'only payment parties can dispute',
      );
    }
    if (payment.status !== 'pending' && payment.status !== 'confirmed') {
      throw new ConflictError(
        ErrorCodes.PAYMENT_INVALID_STATUS,
        'can dispute only pending or confirmed payments',
      );
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.payment.update({
        where: { id: paymentId },
        data: { status: 'disputed', disputedAt: this.clock.now() },
      });
      await tx.paymentDispute.create({
        data: { paymentId, openedById: actorUserId, reason, photoKeys },
      });
      await this.feed.emit({
        tx,
        kind: 'payment_disputed',
        projectId: payment.projectId,
        actorId: actorUserId,
        payload: { paymentId, reason, photoCount: photoKeys.length },
      });
      return u;
    });
    return this.serialize(updated);
  }

  async resolve(
    paymentId: string,
    input: { resolution: string; adjustAmount?: number; actorUserId: string },
  ): Promise<Payment> {
    const payment = await this.prisma.payment.findUnique({ where: { id: paymentId } });
    if (!payment) throw new NotFoundError(ErrorCodes.PAYMENT_NOT_FOUND, 'payment not found');
    if (payment.status !== 'disputed') {
      throw new ConflictError(
        ErrorCodes.PAYMENT_INVALID_STATUS,
        'can resolve only disputed payments',
      );
    }

    const resolvedAmount =
      input.adjustAmount !== undefined
        ? Money.ofKopeks(input.adjustAmount).ensureNonNegative().kopeks()
        : payment.amount;

    const now = this.clock.now();
    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.payment.update({
        where: { id: paymentId },
        data: {
          status: 'resolved',
          resolvedAt: now,
          resolvedAmount,
        },
      });
      await tx.paymentDispute.updateMany({
        where: { paymentId, status: 'open' },
        data: {
          status: 'resolved',
          resolution: input.resolution,
          resolvedAt: now,
          resolvedBy: input.actorUserId,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'payment_resolved',
        projectId: payment.projectId,
        actorId: input.actorUserId,
        payload: { paymentId, resolvedAmount: Number(resolvedAmount) },
      });
      await this.feed.emit({
        tx,
        kind: 'budget_updated',
        projectId: payment.projectId,
        actorId: input.actorUserId,
        payload: { reason: 'payment_resolved', paymentId },
      });
      return u;
    });
    return this.serialize(updated);
  }

  async listForProject(
    projectId: string,
    filter?: { status?: PaymentStatus; kind?: PaymentKind; userId?: string },
  ): Promise<Payment[]> {
    const where: Prisma.PaymentWhereInput = { projectId };
    if (filter?.status) where.status = filter.status;
    if (filter?.kind) where.kind = filter.kind;
    if (filter?.userId) {
      where.OR = [{ fromUserId: filter.userId }, { toUserId: filter.userId }];
    }
    const rows = await this.prisma.payment.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((p) => this.serialize(p));
  }

  async get(id: string): Promise<Payment> {
    const p = await this.prisma.payment.findUnique({
      where: { id },
      include: { children: true, disputes: true },
    });
    if (!p) throw new NotFoundError(ErrorCodes.PAYMENT_NOT_FOUND, 'payment not found');
    return this.serialize(p);
  }

  private serialize<T extends { amount: bigint; resolvedAmount?: bigint | null }>(p: T): T {
    return {
      ...p,
      amount: Number(p.amount) as any,
      resolvedAmount: p.resolvedAmount != null ? (Number(p.resolvedAmount) as any) : null,
    };
  }
}
