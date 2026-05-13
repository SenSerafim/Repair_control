import { forwardRef, Inject, Injectable } from '@nestjs/common';
import { MaterialRequest, Prisma } from '@prisma/client';
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
import { ApprovalsService } from '../approvals/approvals.service';

/**
 * Жизненный цикл заявки на материалы — простой и прозрачный.
 *
 *   pending_approval ──approve──▶ open (= «Согласовано»)
 *          │
 *          └──reject──▶ cancelled (= «Отклонено»)
 *
 * Правила:
 * - Создаёт foreman/master → `pending_approval` + зеркальный Approval(material_purchase)
 *   на заказчика.
 * - customer-owner / representative.canApprove создаёт сразу `open` (согласовано)
 *   и в той же транзакции списывается materialsBudget на сумму items.totalPrice.
 * - Заказчик одобряет (`approved`) → status=open + декремент бюджета.
 * - Заказчик отклоняет (`rejected`) → status=cancelled. Бюджет не трогается,
 *   запись остаётся в истории и видна всем участникам проекта.
 *
 * Все доменные изменения публикуются в feed → все роли видят их сразу.
 *
 * NB: Значения enum в БД (`open`, `cancelled`) сохранены ради обратной совместимости
 * со схемой. UI отображает их как «Согласовано»/«Отклонено».
 */

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
    @Inject(forwardRef(() => ApprovalsService))
    private readonly approvals: ApprovalsService,
  ) {}

  /**
   * Создаёт заявку.
   * - customer-owner / representative.canApprove → сразу `open` (согласовано),
   *   materialsBudget декрементится на items.totalPrice в той же транзакции.
   * - foreman / master → `pending_approval` + Approval(material_purchase) заказчику.
   */
  async createRequest(input: CreateRequestInput): Promise<MaterialRequest> {
    if (input.items.length === 0) {
      throw new InvalidInputError(
        ErrorCodes.MATERIAL_INVALID_STATUS,
        'at least one item is required',
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

    const m = await this.prisma.membership.findFirst({
      where: { projectId: project.id, userId: input.actorUserId, removedAt: null },
      select: { role: true, permissions: true },
    });
    if (!m) {
      throw new ForbiddenError(ErrorCodes.FORBIDDEN, 'actor is not a member of project');
    }

    const perms = (m.permissions ?? {}) as Record<string, boolean | undefined>;
    const isCustomerOwner = project.ownerId === input.actorUserId;
    const canApproveDirectly =
      isCustomerOwner || (m.role === 'representative' && !!perms.canApprove);

    const now = this.clock.now();

    return this.prisma.$transaction(async (tx) => {
      const created = await tx.materialRequest.create({
        data: {
          projectId: project.id,
          stageId: input.stageId ?? null,
          createdById: input.actorUserId,
          recipient: input.recipient,
          title: input.title.trim(),
          comment: input.comment,
          status: canApproveDirectly ? 'open' : 'pending_approval',
          finalizedAt: canApproveDirectly ? now : null,
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
        payload: { requestId: created.id, stageId: input.stageId, recipient: input.recipient },
      });

      if (canApproveDirectly) {
        const totalKopeks = created.items.reduce(
          (acc, it) => acc + Number(it.totalPrice ?? BigInt(0)),
          0,
        );
        await this.feed.emit({
          tx,
          kind: 'material_request_approved',
          projectId: project.id,
          actorId: input.actorUserId,
          payload: { requestId: created.id, autoApproved: true },
        });
        // 2026-05-13: ранее тут был decrement project.materialsBudget на
        // totalKopeks. BudgetCalculator (`materialsSpent`) и так суммирует
        // approved-материалы → получалось ДВОЙНОЕ списание (планируемый
        // бюджет уменьшался, а calculator снова вычитал ту же сумму через
        // spent). Источник истины — calculator; здесь только feed-событие
        // для аудита/уведомлений.
        if (totalKopeks > 0) {
          await this.feed.emit({
            tx,
            kind: 'budget_updated',
            projectId: project.id,
            actorId: input.actorUserId,
            payload: {
              delta: -totalKopeks,
              reason: 'material_approved',
              requestId: created.id,
            },
          });
        }
        return created;
      }

      // foreman / master → нужно согласование заказчика.
      const estimate = created.items.reduce(
        (acc, it) => acc + Number(it.totalPrice ?? BigInt(0)),
        0,
      );
      await this.approvals.request({
        scope: 'material_purchase',
        projectId: project.id,
        stageId: input.stageId,
        addresseeId: project.ownerId,
        actorRole: 'customer',
        payload: {
          materialRequestId: created.id,
          title: created.title,
          amount: estimate,
          recipient: input.recipient,
          stageId: input.stageId ?? null,
          comment: input.comment ?? null,
        },
        requestedById: input.actorUserId,
        tx,
      });

      return created;
    });
  }

  /**
   * Делегирование из ApprovalsService.decide для scope=material_purchase.
   *   approved → status=open + декремент бюджета на items.totalPrice
   *   rejected → status=cancelled (бюджет не трогается)
   */
  async resolvePurchaseApproval(
    materialRequestId: string,
    input: {
      decision: 'approved' | 'rejected';
      comment?: string;
      actorUserId: string;
      actorSystemRole: 'customer' | 'representative' | 'contractor' | 'master' | 'admin';
    },
  ) {
    const r = await this.prisma.materialRequest.findUnique({
      where: { id: materialRequestId },
      include: { items: true },
    });
    if (!r) throw new NotFoundError(ErrorCodes.MATERIAL_REQUEST_NOT_FOUND, 'request not found');
    if (r.status !== 'pending_approval') {
      throw new ConflictError(
        ErrorCodes.MATERIAL_INVALID_STATUS,
        `cannot resolve in status ${r.status}`,
      );
    }

    const now = this.clock.now();
    return this.prisma.$transaction(async (tx) => {
      if (input.decision === 'approved') {
        const updated = await tx.materialRequest.update({
          where: { id: materialRequestId },
          data: { status: 'open', finalizedAt: now },
        });
        const totalKopeks = r.items.reduce(
          (acc, it) => acc + Number(it.totalPrice ?? BigInt(0)),
          0,
        );
        await this.feed.emit({
          tx,
          kind: 'material_request_approved',
          projectId: r.projectId,
          actorId: input.actorUserId,
          payload: { requestId: materialRequestId, comment: input.comment ?? null },
        });
        // 2026-05-13: убрали decrement project.materialsBudget — он давал
        // двойное вычитание (см. coмent в createRequest). Calculator
        // суммирует одобренные materialRequest.items.totalPrice сам.
        if (totalKopeks > 0) {
          await this.feed.emit({
            tx,
            kind: 'budget_updated',
            projectId: r.projectId,
            actorId: input.actorUserId,
            payload: {
              delta: -totalKopeks,
              reason: 'material_approved',
              requestId: materialRequestId,
            },
          });
        }
        return updated;
      }

      const updated = await tx.materialRequest.update({
        where: { id: materialRequestId },
        data: { status: 'cancelled' },
      });
      await this.feed.emit({
        tx,
        kind: 'material_request_cancelled',
        projectId: r.projectId,
        actorId: input.actorUserId,
        payload: { requestId: materialRequestId, comment: input.comment ?? null },
      });
      return updated;
    });
  }

  async get(id: string): Promise<MaterialRequest> {
    const r = await this.prisma.materialRequest.findUnique({
      where: { id },
      include: { items: true },
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
}
