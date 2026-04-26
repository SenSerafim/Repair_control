import { Injectable } from '@nestjs/common';
import { Approval, ApprovalScope, ApprovalStatus, Prisma } from '@prisma/client';
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
import { ProgressCalculator } from '../stages/progress-calculator';

export interface CreateApprovalInput {
  scope: ApprovalScope;
  projectId: string;
  stageId?: string;
  stepId?: string;
  addresseeId: string;
  payload?: Record<string, unknown>;
  attachmentKeys?: string[];
  requestedById: string;
  tx?: Prisma.TransactionClient;
}

export interface DecideInput {
  actorUserId: string;
  actorSystemRole: 'customer' | 'representative' | 'contractor' | 'master' | 'admin';
  decision: 'approved' | 'rejected';
  comment?: string;
}

@Injectable()
export class ApprovalsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
    private readonly calc: ProgressCalculator,
    private readonly clock: Clock,
  ) {}

  /**
   * Создать запрос на согласование. Используется напрямую foreman/master и
   * косвенно из StepsService (extra_work) и StagesService (stage_accept).
   */
  async request(input: CreateApprovalInput): Promise<Approval> {
    const run = async (tx: Prisma.TransactionClient): Promise<Approval> => {
      await this.validateRequest(input, tx);
      const created = await tx.approval.create({
        data: {
          scope: input.scope,
          projectId: input.projectId,
          stageId: input.stageId ?? null,
          stepId: input.stepId ?? null,
          payload: (input.payload ?? {}) as Prisma.InputJsonValue,
          requestedById: input.requestedById,
          addresseeId: input.addresseeId,
          status: 'pending',
          attemptNumber: 1,
        },
      });
      await tx.approvalAttempt.create({
        data: {
          approvalId: created.id,
          attemptNumber: 1,
          action: 'created',
          actorId: input.requestedById,
        },
      });
      if (input.attachmentKeys?.length) {
        for (const key of input.attachmentKeys) {
          await tx.approvalAttachment.create({
            data: {
              approvalId: created.id,
              fileKey: key,
              mimeType: 'image/jpeg',
              sizeBytes: 0,
              uploadedBy: input.requestedById,
            },
          });
        }
      }
      await this.feed.emit({
        tx,
        kind: 'approval_requested',
        projectId: input.projectId,
        actorId: input.requestedById,
        payload: {
          approvalId: created.id,
          scope: input.scope,
          stageId: input.stageId,
          stepId: input.stepId,
          addresseeId: input.addresseeId,
        },
      });
      return created;
    };

    if (input.tx) return run(input.tx);
    return this.prisma.$transaction(run);
  }

  async get(approvalId: string): Promise<Approval> {
    const a = await this.prisma.approval.findUnique({
      where: { id: approvalId },
      include: { attempts: { orderBy: { createdAt: 'asc' } }, attachments: true },
    });
    if (!a) throw new NotFoundError(ErrorCodes.APPROVAL_NOT_FOUND, 'approval not found');
    return a;
  }

  async listForProject(
    projectId: string,
    filter?: { scope?: ApprovalScope; status?: ApprovalStatus; addresseeId?: string },
  ): Promise<Approval[]> {
    return this.prisma.approval.findMany({
      where: {
        projectId,
        ...(filter?.scope ? { scope: filter.scope } : {}),
        ...(filter?.status ? { status: filter.status } : {}),
        ...(filter?.addresseeId ? { addresseeId: filter.addresseeId } : {}),
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async decide(approvalId: string, input: DecideInput): Promise<Approval> {
    const approval = await this.prisma.approval.findUnique({
      where: { id: approvalId },
      include: {
        stage: { select: { foremanIds: true, projectId: true } },
        project: { select: { ownerId: true } },
      },
    });
    if (!approval) throw new NotFoundError(ErrorCodes.APPROVAL_NOT_FOUND, 'approval not found');
    if (approval.status !== 'pending') {
      throw new ConflictError(
        ErrorCodes.APPROVAL_INVALID_STATUS,
        `approval is ${approval.status}, decide not allowed`,
      );
    }
    if (input.decision === 'rejected' && (!input.comment || input.comment.trim().length === 0)) {
      throw new InvalidInputError(
        ErrorCodes.APPROVAL_REJECT_COMMENT_REQUIRED,
        'comment is required when rejecting',
      );
    }

    const isProjectOwner =
      input.actorSystemRole === 'customer' && approval.project.ownerId === input.actorUserId;
    // Подгружаем membership актёра для определения canApprove (у representative)
    let canApproveRight = false;
    if (input.actorSystemRole === 'representative') {
      const m = await this.prisma.membership.findFirst({
        where: { projectId: approval.projectId, userId: input.actorUserId, role: 'representative' },
        select: { permissions: true },
      });
      const perms = (m?.permissions ?? {}) as Record<string, boolean | undefined>;
      canApproveRight = !!perms.canApprove;
    }

    // Проверка «customer не решает мимо бригадира» (gaps §3.3)
    // Если адресат — бригадир, customer (даже owner) не может опередить его решением
    if (
      approval.scope === 'step' &&
      approval.stage?.foremanIds?.length &&
      isProjectOwner &&
      approval.stage.foremanIds.includes(approval.addresseeId) &&
      input.actorUserId !== approval.addresseeId
    ) {
      throw new ForbiddenError(
        ErrorCodes.APPROVAL_CUSTOMER_BYPASS_FOREMAN,
        'customer cannot approve step before foreman',
      );
    }

    // Право решать: addressee OR customer(owner) OR representative.canApprove OR admin
    const canDecide =
      input.actorUserId === approval.addresseeId ||
      isProjectOwner ||
      (input.actorSystemRole === 'representative' && canApproveRight) ||
      input.actorSystemRole === 'admin';
    if (!canDecide) {
      throw new ForbiddenError(
        ErrorCodes.APPROVAL_DECIDE_FORBIDDEN,
        'actor cannot decide this approval',
      );
    }

    const now = this.clock.now();
    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.approval.update({
        where: { id: approvalId },
        data: {
          status: input.decision,
          decidedAt: now,
          decidedById: input.actorUserId,
          decisionComment: input.comment,
        },
      });
      await tx.approvalAttempt.create({
        data: {
          approvalId,
          attemptNumber: approval.attemptNumber,
          action: input.decision,
          actorId: input.actorUserId,
          comment: input.comment,
        },
      });
      await this.feed.emit({
        tx,
        kind: input.decision === 'approved' ? 'approval_approved' : 'approval_rejected',
        projectId: approval.projectId,
        actorId: input.actorUserId,
        payload: {
          approvalId,
          scope: approval.scope,
          stageId: approval.stageId,
          stepId: approval.stepId,
        },
      });
      await this.applyDecisionEffect(tx, u, input);
      return u;
    });
    return updated;
  }

  async resubmit(
    approvalId: string,
    input: { payload?: Record<string, unknown>; attachmentKeys?: string[]; actorUserId: string },
  ): Promise<Approval> {
    const approval = await this.prisma.approval.findUnique({ where: { id: approvalId } });
    if (!approval) throw new NotFoundError(ErrorCodes.APPROVAL_NOT_FOUND, 'approval not found');
    if (approval.requestedById !== input.actorUserId) {
      throw new ForbiddenError(
        ErrorCodes.APPROVAL_RESUBMIT_AUTHOR_ONLY,
        'only requester can resubmit',
      );
    }
    if (approval.status !== 'rejected') {
      throw new ConflictError(
        ErrorCodes.APPROVAL_RESUBMIT_INVALID_STATUS,
        'resubmit allowed only from rejected',
      );
    }

    const nextAttempt = approval.attemptNumber + 1;
    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.approval.update({
        where: { id: approvalId },
        data: {
          status: 'pending',
          attemptNumber: nextAttempt,
          payload: input.payload
            ? (input.payload as Prisma.InputJsonValue)
            : (approval.payload as Prisma.InputJsonValue),
          decidedAt: null,
          decidedById: null,
          decisionComment: null,
        },
      });
      await tx.approvalAttempt.create({
        data: {
          approvalId,
          attemptNumber: nextAttempt,
          action: 'resubmitted',
          actorId: input.actorUserId,
        },
      });
      if (input.attachmentKeys?.length) {
        for (const key of input.attachmentKeys) {
          await tx.approvalAttachment.create({
            data: {
              approvalId,
              fileKey: key,
              mimeType: 'image/jpeg',
              sizeBytes: 0,
              uploadedBy: input.actorUserId,
            },
          });
        }
      }
      await this.feed.emit({
        tx,
        kind: 'approval_resubmitted',
        projectId: approval.projectId,
        actorId: input.actorUserId,
        payload: { approvalId, attemptNumber: nextAttempt },
      });
      return u;
    });
    return updated;
  }

  async cancel(approvalId: string, actorUserId: string): Promise<Approval> {
    const approval = await this.prisma.approval.findUnique({ where: { id: approvalId } });
    if (!approval) throw new NotFoundError(ErrorCodes.APPROVAL_NOT_FOUND, 'approval not found');
    if (approval.requestedById !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.APPROVAL_CANCEL_AUTHOR_ONLY, 'only requester can cancel');
    }
    if (approval.status !== 'pending') {
      throw new ConflictError(
        ErrorCodes.APPROVAL_CANCEL_INVALID_STATUS,
        'cancel allowed only from pending',
      );
    }
    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.approval.update({
        where: { id: approvalId },
        data: { status: 'cancelled' },
      });
      await tx.approvalAttempt.create({
        data: {
          approvalId,
          attemptNumber: approval.attemptNumber,
          action: 'cancelled',
          actorId: actorUserId,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'approval_cancelled',
        projectId: approval.projectId,
        actorId: actorUserId,
        payload: { approvalId },
      });
      return u;
    });
    return updated;
  }

  // ---- private ----

  private async validateRequest(
    input: CreateApprovalInput,
    client: Prisma.TransactionClient,
  ): Promise<void> {
    const project = await client.project.findUnique({
      where: { id: input.projectId },
      select: { id: true, status: true, ownerId: true },
    });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
    if (project.status === 'archived') {
      throw new ConflictError(ErrorCodes.PROJECT_ARCHIVED, 'archived project');
    }

    if (!input.addresseeId) {
      throw new InvalidInputError(
        ErrorCodes.APPROVAL_ADDRESSEE_REQUIRED,
        'addresseeId is required',
      );
    }

    // Gaps §3.3: master не может запрашивать план / приёмку этапа мимо бригадира.
    // План и приёмку этапа всегда инициирует бригадир (или представитель с правом).
    if (input.scope === 'plan' || input.scope === 'stage_accept') {
      const requesterMembership = await client.membership.findFirst({
        where: { projectId: input.projectId, userId: input.requestedById },
        select: { role: true, permissions: true },
      });
      if (requesterMembership?.role === 'master') {
        throw new ForbiddenError(
          ErrorCodes.FORBIDDEN,
          'master cannot request plan/stage_accept; foreman initiates it',
        );
      }
    }

    switch (input.scope) {
      case 'step':
      case 'extra_work':
        if (!input.stepId) {
          throw new InvalidInputError(
            ErrorCodes.APPROVAL_INVALID_SCOPE,
            `stepId required for scope=${input.scope}`,
          );
        }
        break;
      case 'stage_accept': {
        if (!input.stageId) {
          throw new InvalidInputError(
            ErrorCodes.APPROVAL_INVALID_SCOPE,
            'stageId required for scope=stage_accept',
          );
        }
        const stage = await client.stage.findUnique({
          where: { id: input.stageId },
          select: { status: true },
        });
        if (!stage) {
          throw new NotFoundError(ErrorCodes.STAGE_NOT_FOUND, 'stage not found');
        }
        if (stage.status !== 'review') {
          throw new ConflictError(
            ErrorCodes.APPROVAL_STAGE_NOT_IN_REVIEW,
            `stage_accept requires status=review, was ${stage.status}`,
          );
        }
        break;
      }
      case 'deadline_change': {
        if (!input.stageId) {
          throw new InvalidInputError(
            ErrorCodes.APPROVAL_INVALID_SCOPE,
            'stageId required for scope=deadline_change',
          );
        }
        const newEndRaw = (input.payload as any)?.newEnd;
        if (!newEndRaw) {
          throw new InvalidInputError(
            ErrorCodes.APPROVAL_INVALID_SCOPE,
            'payload.newEnd required for deadline_change',
          );
        }
        const newEnd = new Date(newEndRaw);
        if (newEnd.getTime() <= this.clock.now().getTime()) {
          throw new InvalidInputError(
            ErrorCodes.APPROVAL_DEADLINE_IN_PAST,
            'newEnd must be in the future',
          );
        }
        break;
      }
      case 'plan':
        // план требует чтобы scope был customer-facing; stageId не обязателен
        break;
    }
  }

  private async applyDecisionEffect(
    tx: Prisma.TransactionClient,
    approval: Approval,
    _input: DecideInput,
  ): Promise<void> {
    if (approval.status !== 'approved' && approval.status !== 'rejected') return;
    const now = this.clock.now();
    const payload = approval.payload as Record<string, any>;

    switch (approval.scope) {
      case 'plan': {
        if (approval.status === 'approved') {
          await tx.project.update({
            where: { id: approval.projectId },
            data: { planApproved: true },
          });
          await tx.stage.updateMany({
            where: { projectId: approval.projectId },
            data: { planApproved: true },
          });
          await this.feed.emit({
            tx,
            kind: 'plan_approved',
            projectId: approval.projectId,
            actorId: approval.decidedById ?? undefined,
            payload: { approvalId: approval.id },
          });
        }
        break;
      }
      case 'stage_accept': {
        if (!approval.stageId) return;
        if (approval.status === 'approved') {
          await tx.stage.update({
            where: { id: approval.stageId },
            data: { status: 'done', doneAt: now },
          });
          await this.feed.emit({
            tx,
            kind: 'stage_accepted',
            projectId: approval.projectId,
            actorId: approval.decidedById ?? undefined,
            payload: { stageId: approval.stageId, approvalId: approval.id },
          });
        } else {
          await tx.stage.update({
            where: { id: approval.stageId },
            data: { status: 'rejected' },
          });
          await this.feed.emit({
            tx,
            kind: 'stage_rejected_by_customer',
            projectId: approval.projectId,
            actorId: approval.decidedById ?? undefined,
            payload: {
              stageId: approval.stageId,
              approvalId: approval.id,
              comment: approval.decisionComment,
            },
          });
        }
        await this.calc.recalcStage(approval.stageId, tx);
        break;
      }
      case 'extra_work': {
        if (!approval.stepId) return;
        const step = await tx.step.findUnique({ where: { id: approval.stepId } });
        if (!step) return;
        if (approval.status === 'approved') {
          const price = step.price ?? BigInt(0);
          await tx.step.update({
            where: { id: step.id },
            data: { status: 'pending' },
          });
          await tx.stage.update({
            where: { id: step.stageId },
            data: { workBudget: { increment: price } },
          });
          await this.feed.emit({
            tx,
            kind: 'budget_updated',
            projectId: approval.projectId,
            actorId: approval.decidedById ?? undefined,
            payload: {
              stageId: step.stageId,
              delta: Number(price),
              reason: 'extra_work_approved',
              approvalId: approval.id,
            },
          });
          await this.calc.recalcStage(step.stageId, tx);
        } else {
          await tx.step.update({
            where: { id: step.id },
            data: { status: 'rejected' },
          });
          await this.calc.recalcStage(step.stageId, tx);
        }
        break;
      }
      case 'deadline_change': {
        if (!approval.stageId) return;
        if (approval.status === 'approved') {
          const newEndIso = payload?.newEnd;
          if (newEndIso) {
            const newEnd = new Date(newEndIso);
            await tx.stage.update({
              where: { id: approval.stageId },
              data: { plannedEnd: newEnd, originalEnd: newEnd },
            });
            await this.feed.emit({
              tx,
              kind: 'deadline_changed',
              projectId: approval.projectId,
              actorId: approval.decidedById ?? undefined,
              payload: { stageId: approval.stageId, newEnd },
            });
            await this.feed.emit({
              tx,
              kind: 'stage_deadline_recalculated',
              projectId: approval.projectId,
              actorId: approval.decidedById ?? undefined,
              payload: { stageId: approval.stageId, newEnd },
            });
          }
        }
        break;
      }
      case 'step': {
        if (!approval.stepId) return;
        if (approval.status === 'approved') {
          const step = await tx.step.update({
            where: { id: approval.stepId },
            data: { status: 'done', doneAt: now, doneById: approval.decidedById ?? undefined },
          });
          await this.calc.recalcStage(step.stageId, tx);
        }
        break;
      }
    }
  }
}
