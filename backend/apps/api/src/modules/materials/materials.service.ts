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
import { FilesService } from '@app/files';
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
    /** Срок поставки позиции (ISO date) — ТЗ NEWFIX §5.5. */
    dueDate?: string;
    /** Фото позиции (presigned-загружено) — ТЗ NEWFIX §5.2. */
    photo?: {
      fileKey: string;
      thumbKey?: string;
      mimeType: string;
      sizeBytes: number;
      exifCleared?: boolean;
    };
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
    private readonly files: FilesService,
  ) {}

  /**
   * Серафим 08.06.2026: фото позиции — отдаём с presigned URL, чтобы
   * мобилка могла сразу показать миниатюру в детале заявки.
   * Сбоит → отдаём null (UI деградирует gracefully).
   */
  private async attachPhotoUrls<T extends { items: any[] }>(req: T): Promise<T> {
    if (!req.items) return req;
    for (const item of req.items) {
      if (item.photo && item.photo.fileKey) {
        try {
          const got = await this.files.createPresignedDownload(item.photo.fileKey);
          item.photo.url = got.url;
        } catch {
          item.photo.url = null;
        }
        if (item.photo.thumbKey) {
          try {
            const got = await this.files.createPresignedDownload(item.photo.thumbKey);
            item.photo.thumbUrl = got.url;
          } catch {
            item.photo.thumbUrl = item.photo.url ?? null;
          }
        } else {
          item.photo.thumbUrl = item.photo.url ?? null;
        }
      }
    }
    return req;
  }

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
              dueDate: it.dueDate ? new Date(it.dueDate) : null,
              photo: it.photo
                ? {
                    create: {
                      fileKey: it.photo.fileKey,
                      thumbKey: it.photo.thumbKey ?? null,
                      mimeType: it.photo.mimeType,
                      sizeBytes: it.photo.sizeBytes,
                      uploadedBy: input.actorUserId,
                      exifCleared: it.photo.exifCleared ?? false,
                    },
                  }
                : undefined,
            })),
          },
        },
        include: { items: { include: { photo: true } } },
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
      include: { items: { include: { photo: true } } },
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
      include: { items: { include: { photo: true } } },
    });
    if (!r) throw new NotFoundError(ErrorCodes.MATERIAL_REQUEST_NOT_FOUND, 'request not found');
    return this.attachPhotoUrls(r);
  }

  async listForProject(
    projectId: string,
    filter?: { status?: string; stageId?: string },
  ): Promise<MaterialRequest[]> {
    const where: Prisma.MaterialRequestWhereInput = { projectId };
    if (filter?.status) where.status = filter.status as any;
    if (filter?.stageId) where.stageId = filter.stageId;
    const list = await this.prisma.materialRequest.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: { items: { include: { photo: true } } },
    });
    for (const r of list) await this.attachPhotoUrls(r);
    return list;
  }

  /**
   * Отметить факт доставки заявки. ТЗ NEWFIX §5.7 шаг 1:
   * «Доставка фиксируется первым лицом, кто получил материал».
   * Разрешено любому активному member'у проекта (RBAC: materials.mark_delivered).
   *
   * Допустимые исходные статусы:
   *   - open → delivered (первая доставка)
   *   - accepted_partial → delivered (довоз остатка, §5.7 шаг 6)
   *   - delivered → delivered (idempotent no-op)
   */
  async markDelivered(input: { requestId: string; actorUserId: string }): Promise<MaterialRequest> {
    const existing = await this.prisma.materialRequest.findUnique({
      where: { id: input.requestId },
    });
    if (!existing) {
      throw new NotFoundError(ErrorCodes.MATERIAL_REQUEST_NOT_FOUND, 'request not found');
    }

    if (existing.status === 'delivered') {
      return existing;
    }

    if (existing.status !== 'open' && existing.status !== 'accepted_partial') {
      throw new ConflictError(
        ErrorCodes.MATERIAL_INVALID_STATUS,
        `mark-delivered требует статус open или accepted_partial, получен "${existing.status}"`,
      );
    }

    const now = this.clock.now();
    const updated = await this.prisma.materialRequest.update({
      where: { id: input.requestId },
      data: {
        status: 'delivered',
        deliveredAt: now,
        deliveredById: input.actorUserId,
      },
    });

    await this.feed.emit({
      kind: 'material_delivered',
      projectId: updated.projectId,
      stageId: updated.stageId,
      actorId: input.actorUserId,
      payload: { requestId: updated.id, title: updated.title },
    });

    return updated;
  }

  /**
   * Частичная приёмка заявки. ТЗ NEWFIX §5.7 шаги 4–5:
   * бригадир сверяет фактически привезённое с заявкой, фиксирует actualQty,
   * остаток уходит «в ожидание дополнения».
   *
   * RBAC: materials.accept (foreman / customer_owner / representative.canApprove).
   */
  async acceptPartial(input: {
    requestId: string;
    actorUserId: string;
    items: Array<{ itemId: string; actualQty: number }>;
    comment?: string;
  }): Promise<MaterialRequest> {
    const existing = await this.prisma.materialRequest.findUnique({
      where: { id: input.requestId },
      include: { items: { include: { photo: true } } },
    });
    if (!existing) {
      throw new NotFoundError(ErrorCodes.MATERIAL_REQUEST_NOT_FOUND, 'request not found');
    }
    if (existing.status !== 'delivered') {
      throw new ConflictError(
        ErrorCodes.MATERIAL_INVALID_STATUS,
        `accept-partial требует статус delivered, получен "${existing.status}"`,
      );
    }

    const requestItems = existing.items;
    const byId = new Map(requestItems.map((it) => [it.id, it]));
    for (const inp of input.items) {
      const item = byId.get(inp.itemId);
      if (!item) {
        throw new InvalidInputError(
          ErrorCodes.MATERIAL_ITEM_NOT_FOUND,
          `позиция ${inp.itemId} не принадлежит заявке ${input.requestId}`,
        );
      }
      if (inp.actualQty > Number(item.qty)) {
        throw new InvalidInputError(
          ErrorCodes.INVALID_INPUT,
          `actualQty=${inp.actualQty} превышает qty=${item.qty.toString()} для позиции "${item.name}"`,
        );
      }
    }

    const result = await this.prisma.$transaction(async (tx) => {
      for (const inp of input.items) {
        await tx.materialItem.update({
          where: { id: inp.itemId },
          data: { actualQty: inp.actualQty },
        });
      }
      return tx.materialRequest.update({
        where: { id: input.requestId },
        data: { status: 'accepted_partial' },
      });
    });

    await this.feed.emit({
      kind: 'material_request_accepted_partial',
      projectId: result.projectId,
      stageId: result.stageId,
      actorId: input.actorUserId,
      payload: {
        requestId: result.id,
        title: result.title,
        comment: input.comment ?? null,
      },
    });
    return result;
  }

  /**
   * Полная приёмка заявки. ТЗ NEWFIX §5.7 шаг 4:
   * «всё привезли по позициям и количеству → отмечает Принято полностью».
   * actualQty проставляется = qty для всех позиций.
   *
   * RBAC: materials.accept.
   */
  async acceptFull(input: {
    requestId: string;
    actorUserId: string;
    comment?: string;
  }): Promise<MaterialRequest> {
    const existing = await this.prisma.materialRequest.findUnique({
      where: { id: input.requestId },
      include: { items: { include: { photo: true } } },
    });
    if (!existing) {
      throw new NotFoundError(ErrorCodes.MATERIAL_REQUEST_NOT_FOUND, 'request not found');
    }
    if (existing.status !== 'delivered') {
      throw new ConflictError(
        ErrorCodes.MATERIAL_INVALID_STATUS,
        `accept-full требует статус delivered, получен "${existing.status}"`,
      );
    }

    const requestItems = existing.items;

    const result = await this.prisma.$transaction(async (tx) => {
      for (const item of requestItems) {
        await tx.materialItem.update({
          where: { id: item.id },
          data: { actualQty: item.qty },
        });
      }
      return tx.materialRequest.update({
        where: { id: input.requestId },
        data: { status: 'accepted_full' },
      });
    });

    await this.feed.emit({
      kind: 'material_request_accepted_full',
      projectId: result.projectId,
      stageId: result.stageId,
      actorId: input.actorUserId,
      payload: {
        requestId: result.id,
        title: result.title,
        comment: input.comment ?? null,
      },
    });
    return result;
  }

  async deleteRequest(input: { requestId: string; actorUserId: string }) {
    const request = await this.prisma.materialRequest.findUnique({
      where: { id: input.requestId },
      select: {
        id: true,
        projectId: true,
        stageId: true,
        title: true,
        status: true,
        createdById: true,
      },
    });
    if (!request) {
      throw new NotFoundError(ErrorCodes.MATERIAL_REQUEST_NOT_FOUND, 'material request not found');
    }
    if (request.createdById !== input.actorUserId) {
      throw new ForbiddenError(
        ErrorCodes.MATERIAL_REQUEST_DELETE_AUTHOR_ONLY,
        'only the author can delete a material request',
      );
    }
    // FSM: удалять можно только до согласования (pending_approval) или после
    // отказа/отмены (cancelled). Open/delivered/accepted роняют бюджет.
    if (request.status !== 'pending_approval' && request.status !== 'cancelled') {
      throw new ForbiddenError(
        ErrorCodes.MATERIAL_REQUEST_DELETE_FORBIDDEN_STATUS,
        'cannot delete request after approval — cancel via reject first',
      );
    }
    await this.prisma.$transaction(async (tx) => {
      await tx.materialRequest.delete({ where: { id: request.id } });
      await this.feed.emit({
        tx,
        kind: 'material_request_deleted',
        projectId: request.projectId,
        stageId: request.stageId,
        actorId: input.actorUserId,
        payload: { requestId: request.id, title: request.title },
      });
    });
  }
}
