import { Injectable } from '@nestjs/common';
import { Payment, PaymentKind, Prisma } from '@prisma/client';
import {
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
  /**
   * Опционально. Если передан — distribution «висит» под этим parent-авансом
   * (legacy detail-flow). Если null — простая выплата мастеру из кассы бригадира;
   * связь с конкретным авансом не нужна, баланс кассы считается агрегатом.
   */
  parentPaymentId?: string | null;
  /** Обязателен, если parentPaymentId отсутствует. */
  projectId?: string;
  toUserId: string;
  amount: number;
  stageId?: string;
  comment?: string;
  photoKey?: string;
  actorUserId: string;
  idempotencyKey?: string;
}

/**
 * Контекст наблюдателя для проверки видимости платежей.
 * Заполняется в контроллере на основе Membership + ProjectOwner + RepresentativeRights.
 */
export interface PaymentViewer {
  userId: string;
  isOwner?: boolean;
  membershipRole?: 'customer' | 'representative' | 'foreman' | 'master';
  canSeeBudget?: boolean;
}

/**
 * PaymentsService (simplified 2026-05-12).
 *
 * Платёж = факт передачи денег. Никаких подтверждений, отмен, споров.
 *  - Заказчик/представитель создаёт `advance` напрямую foreman или master.
 *  - Foreman из полученных авансов создаёт `distribution` мастерам.
 *  - Бюджет проекта уменьшается на сумму всех `advance` (см. BudgetCalculator).
 *  - Distributions не уменьшают бюджет повторно — это перераспределение уже
 *    выданных бригадиру денег.
 */
@Injectable()
export class PaymentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
  ) {}

  async createAdvance(input: CreateAdvanceInput): Promise<Payment> {
    const amount = Money.ofKopeks(input.amount).ensurePositive(ErrorCodes.PAYMENT_AMOUNT_INVALID);

    if (input.actorUserId === input.toUserId) {
      throw new ForbiddenError(
        ErrorCodes.PAYMENT_SELF_PAYMENT_FORBIDDEN,
        'cannot create advance to yourself',
      );
    }

    const project = await this.prisma.project.findUnique({
      where: { id: input.projectId },
      select: { id: true, ownerId: true, status: true },
    });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
    if (project.status === 'archived') {
      throw new ConflictError(ErrorCodes.PROJECT_ARCHIVED, 'archived project');
    }

    // Получатель — активный foreman или master проекта (customer→master разрешён).
    const recipient = await this.prisma.membership.findFirst({
      where: {
        projectId: project.id,
        userId: input.toUserId,
        role: { in: ['foreman', 'master'] },
        removedAt: null,
      },
      select: { role: true },
    });
    if (!recipient) {
      throw new InvalidInputError(
        ErrorCodes.PAYMENT_INVALID_RECIPIENT,
        'recipient must be a foreman or master of the project',
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
          recipientRole: recipient.role,
          amount: Number(amount.kopeks()),
        },
      });
      await this.feed.emit({
        tx,
        kind: 'budget_updated',
        projectId: project.id,
        actorId: input.actorUserId,
        payload: { reason: 'payment_created', paymentId: p.id },
      });
      return p;
    });
    return this.serialize(created);
  }

  async createDistribution(input: DistributeInput): Promise<Payment> {
    const amount = Money.ofKopeks(input.amount).ensurePositive(ErrorCodes.PAYMENT_AMOUNT_INVALID);

    if (input.toUserId === input.actorUserId) {
      throw new ForbiddenError(
        ErrorCodes.PAYMENT_SELF_PAYMENT_FORBIDDEN,
        'cannot distribute to yourself',
      );
    }

    // Два режима: через parent-аванс (legacy detail-flow) либо напрямую из
    // кассы бригадира (simpler 2026-05). Во втором случае projectId обязателен.
    let projectId: string;
    let parentId: string | null = null;
    let stageId: string | null = input.stageId ?? null;

    if (input.parentPaymentId) {
      const parent = await this.prisma.payment.findUnique({
        where: { id: input.parentPaymentId },
      });
      if (!parent) {
        throw new NotFoundError(ErrorCodes.PAYMENT_NOT_FOUND, 'parent payment not found');
      }
      if (parent.kind !== 'advance') {
        throw new ConflictError(
          ErrorCodes.PAYMENT_INVALID_STATUS,
          'distribution requires advance parent',
        );
      }
      if (parent.toUserId !== input.actorUserId) {
        throw new ForbiddenError(
          ErrorCodes.PAYMENT_DISTRIBUTE_FORBIDDEN,
          'only parent recipient can distribute',
        );
      }
      projectId = parent.projectId;
      parentId = parent.id;
      stageId = input.stageId ?? parent.stageId ?? null;
    } else {
      if (!input.projectId) {
        throw new InvalidInputError(
          ErrorCodes.INVALID_INPUT,
          'projectId required when parentPaymentId is omitted',
        );
      }
      const project = await this.prisma.project.findUnique({
        where: { id: input.projectId },
        select: { id: true, status: true },
      });
      if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
      if (project.status === 'archived') {
        throw new ConflictError(ErrorCodes.PROJECT_ARCHIVED, 'archived project');
      }
      const actorMembership = await this.prisma.membership.findFirst({
        where: {
          projectId: project.id,
          userId: input.actorUserId,
          role: 'foreman',
          removedAt: null,
        },
      });
      if (!actorMembership) {
        throw new ForbiddenError(
          ErrorCodes.PAYMENT_DISTRIBUTE_FORBIDDEN,
          'only foreman of the project can distribute',
        );
      }
      projectId = project.id;
    }

    const master = await this.prisma.membership.findFirst({
      where: {
        projectId,
        userId: input.toUserId,
        role: 'master',
        removedAt: null,
      },
    });
    if (!master) {
      throw new InvalidInputError(
        ErrorCodes.PAYMENT_INVALID_RECIPIENT,
        'recipient must be a master of the project',
      );
    }

    const created = await this.prisma.$transaction(async (tx) => {
      const p = await tx.payment.create({
        data: {
          projectId,
          stageId,
          parentPaymentId: parentId,
          kind: 'distribution',
          fromUserId: input.actorUserId,
          toUserId: input.toUserId,
          amount: amount.kopeks(),
          comment: input.comment,
          photoKey: input.photoKey,
          idempotencyKey: input.idempotencyKey ?? null,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'payment_distributed',
        projectId,
        actorId: input.actorUserId,
        payload: {
          paymentId: p.id,
          parentPaymentId: parentId,
          toUserId: input.toUserId,
          amount: Number(amount.kopeks()),
        },
      });
      return p;
    });
    return this.serialize(created);
  }

  async listForProject(
    projectId: string,
    viewer: PaymentViewer,
    filter?: { kind?: PaymentKind; userId?: string },
  ): Promise<Payment[]> {
    const where: Prisma.PaymentWhereInput = { projectId };
    if (filter?.kind) where.kind = filter.kind;

    const canSeeAll =
      viewer.isOwner ||
      (viewer.membershipRole === 'representative' && viewer.canSeeBudget === true);
    const ownAnds: Prisma.PaymentWhereInput[] = [];
    if (!canSeeAll) {
      if (viewer.membershipRole === 'foreman' || viewer.membershipRole === 'master') {
        ownAnds.push({
          OR: [{ fromUserId: viewer.userId }, { toUserId: viewer.userId }],
        });
      } else {
        return [];
      }
    }
    if (filter?.userId) {
      ownAnds.push({
        OR: [{ fromUserId: filter.userId }, { toUserId: filter.userId }],
      });
    }
    if (ownAnds.length > 0) {
      where.AND = ownAnds;
    }
    const rows = await this.prisma.payment.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((p) => this.serialize(p));
  }

  async get(id: string, viewer?: PaymentViewer): Promise<Payment> {
    const p = await this.prisma.payment.findUnique({
      where: { id },
      include: {
        children: true,
        project: { select: { ownerId: true } },
      },
    });
    if (!p) throw new NotFoundError(ErrorCodes.PAYMENT_NOT_FOUND, 'payment not found');
    if (viewer) {
      const isOwnerOfProject = viewer.isOwner === true || p.project?.ownerId === viewer.userId;
      const canSeeAll =
        isOwnerOfProject ||
        (viewer.membershipRole === 'representative' && viewer.canSeeBudget === true);
      const isParty = p.fromUserId === viewer.userId || p.toUserId === viewer.userId;
      if (!canSeeAll && !isParty) {
        throw new ForbiddenError(ErrorCodes.FORBIDDEN, 'payment not visible to viewer');
      }
    }
    const rest: Record<string, unknown> = { ...p };
    delete rest.project;
    return this.serialize(rest as typeof p);
  }

  async listChildren(parentId: string, viewer: PaymentViewer): Promise<Payment[]> {
    const parent = await this.prisma.payment.findUnique({
      where: { id: parentId },
      select: {
        id: true,
        projectId: true,
        fromUserId: true,
        toUserId: true,
        project: { select: { ownerId: true } },
      },
    });
    if (!parent) throw new NotFoundError(ErrorCodes.PAYMENT_NOT_FOUND, 'parent payment not found');
    const isOwnerOfProject = viewer.isOwner === true || parent.project?.ownerId === viewer.userId;
    const canSeeAll =
      isOwnerOfProject ||
      (viewer.membershipRole === 'representative' && viewer.canSeeBudget === true) ||
      parent.toUserId === viewer.userId ||
      parent.fromUserId === viewer.userId;
    const where: Prisma.PaymentWhereInput = { parentPaymentId: parentId };
    if (!canSeeAll) {
      if (viewer.membershipRole === 'master') {
        where.OR = [{ fromUserId: viewer.userId }, { toUserId: viewer.userId }];
      } else {
        return [];
      }
    }
    const rows = await this.prisma.payment.findMany({
      where,
      orderBy: { createdAt: 'asc' },
    });
    return rows.map((p) => this.serialize(p));
  }

  private serialize<T extends { amount: bigint }>(p: T): T {
    return {
      ...p,
      amount: Number(p.amount) as any,
    };
  }
}
