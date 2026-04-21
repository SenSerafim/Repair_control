import { Injectable } from '@nestjs/common';
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
}

@Injectable()
export class SelfPurchasesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
    private readonly clock: Clock,
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
      await this.feed.emit({
        tx,
        kind: input.decision === 'approved' ? 'selfpurchase_approved' : 'selfpurchase_rejected',
        projectId: sp.projectId,
        actorId: input.actorUserId,
        payload: { selfPurchaseId: id },
      });
      if (input.decision === 'approved') {
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
    filter?: { status?: SelfPurchaseStatus; byUserId?: string },
  ): Promise<SelfPurchase[]> {
    const where: Prisma.SelfPurchaseWhereInput = { projectId };
    if (filter?.status) where.status = filter.status;
    if (filter?.byUserId) where.byUserId = filter.byUserId;
    const rows = await this.prisma.selfPurchase.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => this.serialize(r));
  }

  async get(id: string): Promise<SelfPurchase> {
    const sp = await this.prisma.selfPurchase.findUnique({ where: { id } });
    if (!sp) throw new NotFoundError(ErrorCodes.SELFPURCHASE_NOT_FOUND, 'selfpurchase not found');
    return this.serialize(sp);
  }

  private serialize<T extends { amount: bigint }>(sp: T): T {
    return { ...sp, amount: Number(sp.amount) as any };
  }
}
