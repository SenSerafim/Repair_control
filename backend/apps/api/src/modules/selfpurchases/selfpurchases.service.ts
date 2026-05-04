import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { Prisma, SelfPurchase, SelfPurchaseBy, SelfPurchaseStatus } from '@prisma/client';
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
import { ApprovalsService } from '../approvals/approvals.service';

export interface CreateSelfPurchaseInput {
  projectId: string;
  stageId?: string;
  amount: number;
  comment?: string;
  photoKeys?: string[];
  actorUserId: string;
  idempotencyKey?: string;
}

export interface DecideSelfPurchaseInput {
  decision: 'approved' | 'rejected';
  comment?: string;
  actorUserId: string;
  /**
   * 3-tier forwarding (master→foreman→customer). При approve бригадиром
   * самозакупа от мастера, если флаг === true, в той же транзакции создаётся
   * вторая запись `byRole=foreman`, `addresseeId=ownerId`, `forwardedFromId=id`.
   * Бюджет получает сумму только когда заказчик одобрит forward-копию.
   * Игнорируется, если оригинал не master или decision=rejected.
   */
  forwardOnApprove?: boolean;
}

/**
 * Контекст наблюдателя для проверки видимости самозакупов (TODO §2A.2).
 * - master → видит только byUserId=self;
 * - foreman → свои byUserId=self + входящие addresseeId=self;
 * - owner / canApprove-представитель → только byRole=foreman;
 * - остальные → ничего.
 */
export interface SelfPurchaseViewer {
  userId: string;
  isOwner?: boolean;
  membershipRole?: 'customer' | 'representative' | 'foreman' | 'master';
  canApprove?: boolean;
}

@Injectable()
export class SelfPurchasesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
    private readonly clock: Clock,
    @Inject(forwardRef(() => ApprovalsService))
    private readonly approvals: ApprovalsService,
  ) {}

  async create(input: CreateSelfPurchaseInput): Promise<SelfPurchase> {
    const amount = Money.ofKopeks(input.amount).ensurePositive();

    const project = await this.prisma.project.findUnique({
      where: { id: input.projectId },
      select: { id: true, ownerId: true, status: true },
    });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
    if (project.status === 'archived') {
      throw new ConflictError(ErrorCodes.PROJECT_ARCHIVED, 'archived project');
    }

    // Определяем роль актёра в проекте → byRole + addresseeId
    const membership = await this.prisma.membership.findFirst({
      where: { projectId: project.id, userId: input.actorUserId },
      select: { role: true },
    });
    if (!membership || !['foreman', 'master'].includes(membership.role)) {
      throw new ForbiddenError(
        ErrorCodes.SELFPURCHASE_INVALID_ACTOR,
        'only foreman or master can create selfpurchase',
      );
    }

    let byRole: SelfPurchaseBy;
    let addresseeId: string;
    if (membership.role === 'foreman') {
      byRole = 'foreman';
      addresseeId = project.ownerId; // foreman → customer подтверждает
    } else {
      byRole = 'master';
      // master → addressee = foreman стадии (gaps §4.3)
      if (!input.stageId) {
        throw new InvalidInputError(
          ErrorCodes.SELFPURCHASE_NO_FOREMAN_ON_STAGE,
          'master must specify stageId',
        );
      }
      const stage = await this.prisma.stage.findUnique({
        where: { id: input.stageId },
        select: { foremanIds: true },
      });
      if (!stage || stage.foremanIds.length === 0) {
        throw new InvalidInputError(
          ErrorCodes.SELFPURCHASE_NO_FOREMAN_ON_STAGE,
          'stage has no foreman to approve selfpurchase',
        );
      }
      addresseeId = stage.foremanIds[0];
    }

    const created = await this.prisma.$transaction(async (tx) => {
      const sp = await tx.selfPurchase.create({
        data: {
          projectId: project.id,
          stageId: input.stageId ?? null,
          byUserId: input.actorUserId,
          byRole,
          addresseeId,
          amount: amount.kopeks(),
          comment: input.comment,
          photoKeys: input.photoKeys ?? [],
          status: 'pending',
          idempotencyKey: input.idempotencyKey ?? null,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'selfpurchase_created',
        projectId: project.id,
        actorId: input.actorUserId,
        payload: {
          selfPurchaseId: sp.id,
          byRole,
          addresseeId,
          amount: Number(amount.kopeks()),
        },
      });
      // §6.1 — mirror Approval, чтобы заявка попала в общий Inbox согласований.
      // Источник истины — SelfPurchase. ApprovalsService.decide для scope=self_purchase
      // делегирует обратно в SelfPurchasesService.decide; applyDecisionEffect — no-op.
      await this.approvals.request({
        scope: 'self_purchase',
        projectId: project.id,
        stageId: input.stageId,
        addresseeId,
        actorRole: byRole === 'master' ? 'foreman' : 'customer',
        payload: {
          selfPurchaseId: sp.id,
          amount: Number(amount.kopeks()),
          byRole,
          kind: 'materials',
          comment: input.comment ?? null,
        },
        attachmentKeys: input.photoKeys ?? [],
        requestedById: input.actorUserId,
        tx,
      });
      return sp;
    });
    return this.serialize(created);
  }

  async decide(id: string, input: DecideSelfPurchaseInput): Promise<SelfPurchase> {
    const sp = await this.prisma.selfPurchase.findUnique({ where: { id } });
    if (!sp) throw new NotFoundError(ErrorCodes.SELFPURCHASE_NOT_FOUND, 'selfpurchase not found');
    if (sp.status !== 'pending') {
      throw new ConflictError(
        ErrorCodes.SELFPURCHASE_INVALID_STATUS,
        `selfpurchase is ${sp.status}`,
      );
    }
    if (sp.addresseeId !== input.actorUserId) {
      throw new ForbiddenError(
        ErrorCodes.SELFPURCHASE_ADDRESSEE_ONLY,
        'only addressee can decide selfpurchase',
      );
    }
    if (input.decision === 'rejected' && (!input.comment || input.comment.trim().length === 0)) {
      throw new InvalidInputError(
        ErrorCodes.SELFPURCHASE_REJECT_COMMENT_REQUIRED,
        'comment is required when rejecting',
      );
    }

    const now = this.clock.now();
    // 3-tier forwarding активируется только когда foreman approve master-самозакуп
    // и явно запросил forward (`forwardOnApprove: true`). Бюджет в этой ветке
    // НЕ получает сумму на approve бригадиром — только после approve заказчиком
    // у forward-копии.
    const willForward =
      input.decision === 'approved' && input.forwardOnApprove === true && sp.byRole === 'master';

    let project: { id: string; ownerId: string } | null = null;
    if (willForward) {
      project = await this.prisma.project.findUnique({
        where: { id: sp.projectId },
        select: { id: true, ownerId: true },
      });
      if (!project) {
        throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
      }
      if (project.ownerId === input.actorUserId) {
        // Бригадир-актёр не может одновременно быть owner-ом проекта.
        throw new InvalidInputError(
          ErrorCodes.SELFPURCHASE_INVALID_ACTOR,
          'forward target equals actor',
        );
      }
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.selfPurchase.update({
        where: { id },
        data: {
          status: input.decision,
          decidedAt: now,
          decidedById: input.actorUserId,
          decisionComment: input.comment,
        },
      });
      // §6.1 — синхронизировать mirror Approval (scope=self_purchase, payload.selfPurchaseId=id)
      // в pending → approved/rejected. Делаем напрямую, без applyDecisionEffect (он no-op для self_purchase).
      const mirror = await tx.approval.findFirst({
        where: {
          projectId: sp.projectId,
          scope: 'self_purchase',
          status: 'pending',
          payload: { path: ['selfPurchaseId'], equals: id },
        },
        select: { id: true, attemptNumber: true },
      });
      if (mirror) {
        await tx.approval.update({
          where: { id: mirror.id },
          data: {
            status: input.decision,
            decidedAt: now,
            decidedById: input.actorUserId,
            decisionComment: input.comment,
          },
        });
        await tx.approvalAttempt.create({
          data: {
            approvalId: mirror.id,
            attemptNumber: mirror.attemptNumber,
            action: input.decision,
            actorId: input.actorUserId,
            comment: input.comment,
          },
        });
      }
      if (willForward && project) {
        const forwarded = await tx.selfPurchase.create({
          data: {
            projectId: sp.projectId,
            stageId: sp.stageId,
            byUserId: input.actorUserId,
            byRole: 'foreman',
            addresseeId: project.ownerId,
            amount: sp.amount,
            comment: sp.comment,
            photoKeys: sp.photoKeys,
            status: 'pending',
            forwardedFromId: sp.id,
          },
        });
        await this.feed.emit({
          tx,
          kind: 'selfpurchase_forwarded',
          projectId: sp.projectId,
          actorId: input.actorUserId,
          payload: { selfPurchaseId: id, forwardedToOwnerId: project.ownerId },
        });
        // §6.1 — также создаём mirror Approval для forwarded SelfPurchase
        await this.approvals.request({
          scope: 'self_purchase',
          projectId: sp.projectId,
          stageId: sp.stageId ?? undefined,
          addresseeId: project.ownerId,
          actorRole: 'customer',
          payload: {
            selfPurchaseId: forwarded.id,
            amount: Number(sp.amount),
            byRole: 'foreman',
            kind: 'materials',
            comment: sp.comment ?? null,
            forwardedFromSelfPurchaseId: sp.id,
          },
          attachmentKeys: sp.photoKeys ?? [],
          requestedById: input.actorUserId,
          tx,
        });
      } else {
        await this.feed.emit({
          tx,
          kind: input.decision === 'approved' ? 'selfpurchase_approved' : 'selfpurchase_rejected',
          projectId: sp.projectId,
          actorId: input.actorUserId,
          payload: { selfPurchaseId: id },
        });
      }
      if (input.decision === 'approved' && !willForward) {
        // Самозакуп уходит в budget.materials.spent — нет отдельной таблицы spend,
        // BudgetCalculator будет суммировать approved selfpurchases.
        await this.feed.emit({
          tx,
          kind: 'budget_updated',
          projectId: sp.projectId,
          actorId: input.actorUserId,
          payload: {
            reason: 'selfpurchase_approved',
            selfPurchaseId: id,
            amount: Number(sp.amount),
          },
        });
      }
      return u;
    });
    return this.serialize(updated);
  }

  async listForProject(
    projectId: string,
    viewer: SelfPurchaseViewer,
    filter?: { status?: SelfPurchaseStatus; byUserId?: string },
  ): Promise<SelfPurchase[]> {
    const where: Prisma.SelfPurchaseWhereInput = { projectId };
    if (filter?.status) where.status = filter.status;

    // Видимость по матрице 2A.2:
    // - owner / representative.canApprove → видят только foreman→customer (byRole=foreman);
    // - foreman → свои (byRole=foreman, fromUserId=self) + входящие master→foreman (addresseeId=self);
    // - master → только свои (byUserId=self).
    const ands: Prisma.SelfPurchaseWhereInput[] = [];
    if (viewer.isOwner || (viewer.membershipRole === 'representative' && viewer.canApprove)) {
      ands.push({ byRole: 'foreman' });
    } else if (viewer.membershipRole === 'foreman') {
      ands.push({
        OR: [{ byUserId: viewer.userId }, { addresseeId: viewer.userId }],
      });
    } else if (viewer.membershipRole === 'master') {
      ands.push({ byUserId: viewer.userId });
    } else {
      return [];
    }

    if (filter?.byUserId) ands.push({ byUserId: filter.byUserId });
    if (ands.length > 0) where.AND = ands;

    const rows = await this.prisma.selfPurchase.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => this.serialize(r));
  }

  async get(id: string, viewer?: SelfPurchaseViewer): Promise<SelfPurchase> {
    const sp = await this.prisma.selfPurchase.findUnique({ where: { id } });
    if (!sp) throw new NotFoundError(ErrorCodes.SELFPURCHASE_NOT_FOUND, 'selfpurchase not found');
    if (viewer) {
      const isParty = sp.byUserId === viewer.userId || sp.addresseeId === viewer.userId;
      const isOwnerView =
        viewer.isOwner || (viewer.membershipRole === 'representative' && viewer.canApprove);
      // Owner видит только foreman→customer; не видит master→foreman.
      if (isOwnerView && sp.byRole !== 'foreman') {
        throw new ForbiddenError(ErrorCodes.FORBIDDEN, 'master self-purchase hidden from customer');
      }
      if (!isOwnerView && !isParty) {
        throw new ForbiddenError(ErrorCodes.FORBIDDEN, 'selfpurchase not visible to viewer');
      }
    }
    return this.serialize(sp);
  }

  private serialize<T extends { amount: bigint }>(sp: T): T {
    return { ...sp, amount: Number(sp.amount) as any };
  }
}
