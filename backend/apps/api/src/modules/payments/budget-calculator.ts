import { Injectable } from '@nestjs/common';
import { Money, PrismaService } from '@app/common';

export interface BudgetBucket {
  planned: number;
  spent: number;
  remaining: number;
}

export interface StageBudgetDTO {
  stageId: string;
  title: string;
  work: BudgetBucket;
  materials: BudgetBucket;
  total: BudgetBucket;
}

export interface ProjectBudgetDTO {
  work: BudgetBucket;
  materials: BudgetBucket;
  total: BudgetBucket;
  stages: StageBudgetDTO[];
  /**
   * ТЗ §7 / §10: master видит «свои выплаты», без бюджета проекта.
   * Поле заполнено только для master-viewer'а; иначе пусто/undefined.
   * Mobile разруливает экран по наличию `earnings` или `viewerKind === 'master'`.
   */
  viewerKind?: 'owner' | 'representative' | 'foreman' | 'master';
  earnings?: MasterEarning[];
  /**
   * true, когда у бригадира все его этапы имеют workBudget/materialsBudget = 0,
   * но заказчик задал общий Project.workBudget. UI показывает баннер
   * «Заказчик не разнёс бюджет по вашим этапам».
   */
  noStageBudget?: boolean;
}

export interface MasterEarning {
  paymentId: string;
  stageId: string | null;
  amount: number;
  createdAt: Date;
  /**
   * Кто заплатил мастеру. Заполняется в `buildMasterView`, чтобы экран мастера
   * показал «выплатил заказчик / выплатил бригадир Имя Фамилия» — основное
   * требование UX (мастер должен видеть источник денег).
   */
  fromUserId?: string | null;
  fromUserName?: string | null;
  fromUserRole?: 'customer' | 'representative' | 'foreman' | 'master' | null;
}

export interface BudgetViewerContext {
  userId: string;
  isOwner: boolean;
  membershipRole?: 'customer' | 'representative' | 'foreman' | 'master';
  assignedStageIds?: string[];
  canSeeBudget?: boolean;
}

// ---------- P1.5: Money flow («Движение средств») ----------

export interface AdvanceFlow {
  id: string;
  toUserId: string;
  toUserName: string;
  amount: number;
  createdAt: Date;
}

export interface DistributionFlow {
  id: string;
  parentPaymentId: string | null;
  fromUserId: string;
  toUserId: string;
  toUserName: string;
  amount: number;
  createdAt: Date;
}

export interface ApprovedSelfpurchaseFlow {
  id: string;
  byUserId: string;
  byUserName: string;
  amount: number;
  comment: string | null;
  decidedAt: Date | null;
}

export interface MaterialPurchaseFlow {
  requestId: string;
  title: string;
  totalSpent: number;
  itemCount: number;
  /**
   * Кто фактически покупал материал.
   * `customer` — заказчик/представитель (списание сразу).
   * `foreman` — бригадир/мастер (списание после approve заказчиком).
   */
  boughtBy: 'customer' | 'foreman';
  requestedByName: string;
}

/**
 * Материал в статусе `pending_approval` — ждёт решения заказчика.
 * В таб «Материалы» бюджета показывается отдельной полупрозрачной секцией
 * («На согласовании»), в spent НЕ попадает.
 */
export interface PendingMaterialFlow {
  requestId: string;
  title: string;
  estimatedTotal: number;
  itemCount: number;
  requestedByName: string;
  createdAt: Date;
}

/**
 * Материал в статусе `cancelled` (после rejected approval либо отзыва автором)
 * — в spent НЕ попадает, показывается в таб «История» серой строкой.
 */
export interface RejectedMaterialFlow {
  requestId: string;
  title: string;
  estimatedTotal: number;
  itemCount: number;
  requestedByName: string;
  decidedAt: Date;
}

export interface RejectedSelfpurchaseFlow {
  id: string;
  byUserName: string;
  amount: number;
  comment: string | null;
  decidedAt: Date | null;
}

/**
 * Касса бригадира по проекту:
 *   advancesReceived — сумма всех авансов customer→foreman.
 *   distributed      — сумма всех distributions foreman→master.
 *   available        — `advancesReceived - distributed`. Может быть
 *                      отрицательной — бригадир распределил больше, чем
 *                      получил (например, оплатил мастеру из своих карманных).
 */
export interface ForemanWallet {
  advancesReceived: number;
  distributed: number;
  available: number;
}

export interface MoneyFlowTotals {
  advances: number;
  distributed: number;
  undistributed: number;
  approvedSelfpurchases: number;
  materials: number;
}

export interface MoneyFlowDTO {
  advances: AdvanceFlow[];
  distributions: DistributionFlow[];
  approvedSelfpurchases: ApprovedSelfpurchaseFlow[];
  materialPurchases: MaterialPurchaseFlow[];
  /** Материалы со статусом `pending_approval` (ждут заказчика). */
  pendingMaterials: PendingMaterialFlow[];
  /** Материалы со статусом `cancelled` (отклонены или отозваны). */
  rejectedMaterials: RejectedMaterialFlow[];
  /** Самозакупы со статусом `rejected`. */
  rejectedSelfpurchases: RejectedSelfpurchaseFlow[];
  /** Касса бригадира — заполняется только когда viewer = foreman. */
  wallet?: ForemanWallet;
  totals: MoneyFlowTotals;
}

/**
 * BudgetCalculator — dynamic view бюджета (ТЗ §4): план + потрачено + остаток.
 *
 * Simplified 2026-05: подтверждений у платежей больше нет, любая запись
 * advance/distribution = факт передачи денег. Spent = sum(advance.amount).
 * Distributions не уменьшают бюджет повторно — это перераспределение уже
 * выданных бригадиру денег.
 */
@Injectable()
export class BudgetCalculator {
  constructor(private readonly prisma: PrismaService) {}

  async getProjectBudget(
    projectId: string,
    viewer: BudgetViewerContext,
  ): Promise<ProjectBudgetDTO> {
    // ТЗ §7/§10 — master не видит общий бюджет проекта, только свои выплаты.
    if (viewer.membershipRole === 'master') {
      return this.buildMasterView(projectId, viewer);
    }

    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      include: {
        stages: { orderBy: { orderIndex: 'asc' } },
      },
    });
    if (!project) {
      return {
        work: { planned: 0, spent: 0, remaining: 0 },
        materials: { planned: 0, spent: 0, remaining: 0 },
        total: { planned: 0, spent: 0, remaining: 0 },
        stages: [],
        viewerKind: this.viewerKindOf(viewer),
      };
    }

    const payments = await this.prisma.payment.findMany({
      where: {
        projectId,
        kind: 'advance',
      },
    });
    const materialRequests = await this.prisma.materialRequest.findMany({
      where: {
        projectId,
        // «Согласовано» = open. UI/UX-упрощение 2026-05: pending → approved | rejected.
        status: 'open',
      },
      include: { items: true },
    });
    // 3-tier forwarding: в бюджет попадают только foreman-самозакупы, одобренные
    // заказчиком (или одноступенчатые foreman→customer). Master-копия с
    // forwardedBy ≠ null НЕ учитывается — её сумма уже представлена в forward.
    const selfPurchases = await this.prisma.selfPurchase.findMany({
      where: { projectId, status: 'approved', byRole: 'foreman' },
    });
    // NEWFIX §5: «Расходы» (чеки этапа/проекта) тоже расходуют бюджет.
    // Маппинг категорий в 2 корзины: materials → «Материалы», остальные
    // (transport/rental/services/other) → «Работы». Так всё попадает в
    // «Потрачено», и work+materials сходятся с total (Егор 23.06.2026).
    const expenses = await this.prisma.expense.findMany({ where: { projectId } });
    const sumExpenses = (rows: typeof expenses): Money =>
      rows.reduce((acc, e) => acc.plus(Money.ofKopeks(e.amount)), Money.zero());
    const expenseWorkAll = sumExpenses(expenses.filter((e) => e.category !== 'materials'));
    const expenseMaterialsAll = sumExpenses(expenses.filter((e) => e.category === 'materials'));

    const workSpent = payments
      .reduce((acc, p) => acc.plus(Money.ofKopeks(p.amount)), Money.zero())
      .plus(expenseWorkAll);
    const materialsFromRequests = materialRequests.reduce(
      (acc, r) =>
        acc.plus(
          r.items.reduce(
            (inner, it) => inner.plus(Money.ofKopeks(it.totalPrice ?? BigInt(0))),
            Money.zero(),
          ),
        ),
      Money.zero(),
    );
    const materialsFromSelfPurchases = selfPurchases.reduce(
      (acc, sp) => acc.plus(Money.ofKopeks(sp.amount)),
      Money.zero(),
    );
    const materialsSpent = materialsFromRequests
      .plus(materialsFromSelfPurchases)
      .plus(expenseMaterialsAll);

    // П1.3 / 5.1 — wizard создаёт проект с workBudget/materialsBudget на Project,
    // но не заводит этапы автоматически. Если сумма по этапам = 0, делаем fallback
    // на Project-level бюджет — иначе пользователь видит «бюджет не задан», хотя
    // он его задавал в wizard'е.
    const stagesWorkSum = project.stages.reduce(
      (acc, s) => acc.plus(Money.ofKopeks(s.workBudget)),
      Money.zero(),
    );
    const stagesMaterialsSum = project.stages.reduce(
      (acc, s) => acc.plus(Money.ofKopeks(s.materialsBudget)),
      Money.zero(),
    );
    const projectWorkBigInt = project.workBudget != null ? BigInt(project.workBudget) : BigInt(0);
    const projectMaterialsBigInt =
      project.materialsBudget != null ? BigInt(project.materialsBudget) : BigInt(0);
    const workPlanned =
      stagesWorkSum.kopeks() === BigInt(0) ? Money.ofKopeks(projectWorkBigInt) : stagesWorkSum;
    const materialsPlanned =
      stagesMaterialsSum.kopeks() === BigInt(0)
        ? Money.ofKopeks(projectMaterialsBigInt)
        : stagesMaterialsSum;

    const stages: StageBudgetDTO[] = project.stages
      .filter((s) => this.stageVisibleTo(viewer, s.id, s.foremanIds))
      .map((s) => {
        const stageExpenseWork = sumExpenses(
          expenses.filter((e) => e.stageId === s.id && e.category !== 'materials'),
        );
        const stageExpenseMaterials = sumExpenses(
          expenses.filter((e) => e.stageId === s.id && e.category === 'materials'),
        );
        const stageWorkSpent = payments
          .filter((p) => p.stageId === s.id)
          .reduce((acc, p) => acc.plus(Money.ofKopeks(p.amount)), Money.zero())
          .plus(stageExpenseWork);
        const stageMaterialsFromReq = materialRequests
          .filter((r) => r.stageId === s.id)
          .reduce(
            (acc, r) =>
              acc.plus(
                r.items.reduce(
                  (inner, it) => inner.plus(Money.ofKopeks(it.totalPrice ?? BigInt(0))),
                  Money.zero(),
                ),
              ),
            Money.zero(),
          );
        const stageMaterialsFromSp = selfPurchases
          .filter((sp) => sp.stageId === s.id)
          .reduce((acc, sp) => acc.plus(Money.ofKopeks(sp.amount)), Money.zero());
        const stageMaterialsSpent = stageMaterialsFromReq
          .plus(stageMaterialsFromSp)
          .plus(stageExpenseMaterials);
        return {
          stageId: s.id,
          title: s.title,
          work: this.bucket(Money.ofKopeks(s.workBudget), stageWorkSpent),
          materials: this.bucket(Money.ofKopeks(s.materialsBudget), stageMaterialsSpent),
          total: this.bucket(
            Money.ofKopeks(s.workBudget).plus(Money.ofKopeks(s.materialsBudget)),
            stageWorkSpent.plus(stageMaterialsSpent),
          ),
        };
      });

    // ТЗ §6 «Бригадир — Видимость»: foreman видит бюджет только своих этапов.
    // 2026-05 рефактор: для foreman пересчитываем top-level суммы по visibleStages,
    // чтобы карточка «Работа / Материалы / Итого» показывала только его сегмент.
    const isForeman = viewer.membershipRole === 'foreman' && !viewer.isOwner;
    const topWorkPlanned = isForeman
      ? stages.reduce((acc, s) => acc.plus(Money.ofKopeks(BigInt(s.work.planned))), Money.zero())
      : workPlanned;
    const topMaterialsPlanned = isForeman
      ? stages.reduce(
          (acc, s) => acc.plus(Money.ofKopeks(BigInt(s.materials.planned))),
          Money.zero(),
        )
      : materialsPlanned;
    const topWorkSpent = isForeman
      ? stages.reduce((acc, s) => acc.plus(Money.ofKopeks(BigInt(s.work.spent))), Money.zero())
      : workSpent;
    const topMaterialsSpent = isForeman
      ? stages.reduce((acc, s) => acc.plus(Money.ofKopeks(BigInt(s.materials.spent))), Money.zero())
      : materialsSpent;

    // Foreman без распределённого бюджета: сигнализируем мобайлу для inline-баннера.
    // Раньше флаг ставился только если у проекта вообще был бюджет; теперь —
    // всякий раз, когда у бригадира нули в шапке (включая случай «совсем нет
    // бюджета»). Это гарантирует, что вместо full-screen «Бюджет не задан»
    // (одинаковый для всех пустых случаев) мобайл покажет inline-баннер и
    // оставит доступ к выплатам/материалам/истории.
    const noStageBudget = isForeman && topWorkPlanned.isZero() && topMaterialsPlanned.isZero();

    return {
      work: this.bucket(topWorkPlanned, topWorkSpent),
      materials: this.bucket(topMaterialsPlanned, topMaterialsSpent),
      total: this.bucket(
        topWorkPlanned.plus(topMaterialsPlanned),
        topWorkSpent.plus(topMaterialsSpent),
      ),
      stages,
      viewerKind: this.viewerKindOf(viewer),
      ...(noStageBudget ? { noStageBudget: true } : {}),
    };
  }

  private viewerKindOf(viewer: BudgetViewerContext): ProjectBudgetDTO['viewerKind'] {
    if (viewer.isOwner) return 'owner';
    if (viewer.membershipRole === 'representative') return 'representative';
    if (viewer.membershipRole === 'foreman') return 'foreman';
    if (viewer.membershipRole === 'master') return 'master';
    return undefined;
  }

  /**
   * Master-side view бюджета: справочная сводка по проекту, без edit-функционала.
   * Показываем:
   *   • `earnings` — только входящие выплаты мастеру (advance toUserId=я,
   *     distribution toUserId=я). С информацией о том, кто и какой ролью
   *     заплатил (`fromUserId` + `fromUserName` + `fromUserRole`), чтобы
   *     мобайл отрисовал «Выплатил заказчик / бригадир Имя Фамилия».
   *   • `planned/spent` оставлены пустыми — UI для мастера полей бюджета
   *     не рисует. Денежное движение проекта мастер видит через отдельный
   *     эндпоинт `/money-flow` (теперь доступен и мастеру read-only).
   */
  private async buildMasterView(
    projectId: string,
    viewer: BudgetViewerContext,
  ): Promise<ProjectBudgetDTO> {
    const myIncomingPayments = await this.prisma.payment.findMany({
      where: {
        projectId,
        toUserId: viewer.userId,
      },
      orderBy: { createdAt: 'desc' },
    });

    const fromUserIds = Array.from(
      new Set(myIncomingPayments.map((p) => p.fromUserId).filter((x): x is string => !!x)),
    );
    const fromUsers =
      fromUserIds.length > 0
        ? await this.prisma.user.findMany({
            where: { id: { in: fromUserIds } },
            select: { id: true, firstName: true, lastName: true },
          })
        : [];
    const userById = new Map(fromUsers.map((u) => [u.id, u]));
    // Роли плательщиков в этом проекте определяем одним запросом: для каждого
    // fromUserId смотрим membership.role или ownerId (для заказчика, у которого
    // может не быть явной customer-membership на legacy-проектах).
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { ownerId: true },
    });
    const memberships =
      fromUserIds.length > 0
        ? await this.prisma.membership.findMany({
            where: { projectId, userId: { in: fromUserIds }, removedAt: null },
            select: { userId: true, role: true },
          })
        : [];
    const roleByUser = new Map<string, 'customer' | 'representative' | 'foreman' | 'master'>();
    for (const m of memberships) {
      roleByUser.set(m.userId, m.role as 'customer' | 'representative' | 'foreman' | 'master');
    }
    if (project?.ownerId) roleByUser.set(project.ownerId, 'customer');

    const earnings: MasterEarning[] = myIncomingPayments.map((p) => {
      const u = p.fromUserId ? userById.get(p.fromUserId) : null;
      const fromName = u ? `${u.firstName ?? ''} ${u.lastName ?? ''}`.trim() : null;
      return {
        paymentId: p.id,
        stageId: p.stageId,
        amount: Number(p.amount),
        createdAt: p.createdAt,
        fromUserId: p.fromUserId,
        fromUserName: fromName,
        fromUserRole: p.fromUserId ? (roleByUser.get(p.fromUserId) ?? null) : null,
      };
    });
    return {
      work: { planned: 0, spent: 0, remaining: 0 },
      materials: { planned: 0, spent: 0, remaining: 0 },
      total: { planned: 0, spent: 0, remaining: 0 },
      stages: [],
      viewerKind: 'master',
      earnings,
    };
  }

  async getStageBudget(
    stageId: string,
    viewer: BudgetViewerContext,
  ): Promise<StageBudgetDTO | null> {
    const stage = await this.prisma.stage.findUnique({ where: { id: stageId } });
    if (!stage) return null;
    if (!this.stageVisibleTo(viewer, stage.id, stage.foremanIds)) return null;

    const payments = await this.prisma.payment.findMany({
      where: { stageId, kind: 'advance' },
    });
    const materialRequests = await this.prisma.materialRequest.findMany({
      where: {
        stageId,
        // «Согласовано» = open.
        status: 'open',
      },
      include: { items: true },
    });
    const stageSelfPurchases = await this.prisma.selfPurchase.findMany({
      where: { stageId, status: 'approved', byRole: 'foreman' },
    });
    const workSpent = payments.reduce((acc, p) => acc.plus(Money.ofKopeks(p.amount)), Money.zero());
    const materialsFromReq = materialRequests.reduce(
      (acc, r) =>
        acc.plus(
          r.items.reduce(
            (inner, it) => inner.plus(Money.ofKopeks(it.totalPrice ?? BigInt(0))),
            Money.zero(),
          ),
        ),
      Money.zero(),
    );
    const materialsFromSp = stageSelfPurchases.reduce(
      (acc, sp) => acc.plus(Money.ofKopeks(sp.amount)),
      Money.zero(),
    );
    const materialsSpent = materialsFromReq.plus(materialsFromSp);
    return {
      stageId: stage.id,
      title: stage.title,
      work: this.bucket(Money.ofKopeks(stage.workBudget), workSpent),
      materials: this.bucket(Money.ofKopeks(stage.materialsBudget), materialsSpent),
      total: this.bucket(
        Money.ofKopeks(stage.workBudget).plus(Money.ofKopeks(stage.materialsBudget)),
        workSpent.plus(materialsSpent),
      ),
    };
  }

  /**
   * P1.5: Возвращает «Движение средств» проекта — авансы customer→foreman,
   * распределения foreman→master, одобренные самозакупы foreman→customer
   * и закупки материалов. Доступно owner / representative.canSeeBudget.
   *
   * 2026-05: для foreman возвращается его срез (только свои входящие/исходящие),
   * чтобы вкладка «История» в бюджете заполнялась его транзакциями.
   * Master уже получает свои выплаты через budget endpoint (earnings[]).
   */
  async getMoneyFlow(
    projectId: string,
    viewer: BudgetViewerContext,
    range?: { from?: Date; to?: Date },
  ): Promise<MoneyFlowDTO> {
    const empty: MoneyFlowDTO = {
      advances: [],
      distributions: [],
      approvedSelfpurchases: [],
      materialPurchases: [],
      pendingMaterials: [],
      rejectedMaterials: [],
      rejectedSelfpurchases: [],
      totals: {
        advances: 0,
        distributed: 0,
        undistributed: 0,
        approvedSelfpurchases: 0,
        materials: 0,
      },
    };
    const allowed = viewer.isOwner || viewer.canSeeBudget === true;
    if (!allowed && viewer.membershipRole === 'foreman') {
      return this.getForemanMoneyFlow(projectId, viewer.userId, range);
    }
    // Мастер видит movement проекта в справочном режиме (без edit-кнопок на UI).
    // Срез — тот же, что у owner: полный список advances/distributions/материалов;
    // мобильный экран рисует только информационные строки.
    if (!allowed && viewer.membershipRole === 'master') {
      // Fall through to full-flow ниже.
    } else if (!allowed) {
      return empty;
    }

    const dateFilter =
      range && (range.from || range.to)
        ? {
            ...(range.from ? { gte: range.from } : {}),
            ...(range.to ? { lte: range.to } : {}),
          }
        : undefined;

    const advances = await this.prisma.payment.findMany({
      where: {
        projectId,
        kind: 'advance',
        ...(dateFilter ? { createdAt: dateFilter } : {}),
      },
      orderBy: { createdAt: 'desc' },
    });
    const distributions = await this.prisma.payment.findMany({
      where: {
        projectId,
        kind: 'distribution',
        ...(dateFilter ? { createdAt: dateFilter } : {}),
      },
      orderBy: { createdAt: 'desc' },
    });
    const approvedSp = await this.prisma.selfPurchase.findMany({
      where: {
        projectId,
        status: 'approved',
        byRole: 'foreman',
        ...(dateFilter ? { decidedAt: dateFilter } : {}),
      },
      orderBy: { decidedAt: 'desc' },
    });
    const materialReqs = await this.prisma.materialRequest.findMany({
      where: {
        projectId,
        // «Согласовано» = open. finalizedAt ставится в момент approve.
        status: 'open',
        ...(dateFilter ? { finalizedAt: dateFilter } : {}),
      },
      include: { items: true },
      orderBy: { createdAt: 'desc' },
    });
    // pending_approval — отдельной секцией «На согласовании», без вычета из spent.
    const pendingMaterialReqs = await this.prisma.materialRequest.findMany({
      where: {
        projectId,
        status: 'pending_approval',
        ...(dateFilter ? { createdAt: dateFilter } : {}),
      },
      include: { items: true },
      orderBy: { createdAt: 'desc' },
    });
    // cancelled — отклонённые/отозванные. Показываем в истории серой строкой.
    const rejectedMaterialReqs = await this.prisma.materialRequest.findMany({
      where: {
        projectId,
        status: 'cancelled',
        ...(dateFilter ? { updatedAt: dateFilter } : {}),
      },
      include: { items: true },
      orderBy: { updatedAt: 'desc' },
    });
    const rejectedSp = await this.prisma.selfPurchase.findMany({
      where: {
        projectId,
        status: 'rejected',
        ...(dateFilter ? { decidedAt: dateFilter } : {}),
      },
      orderBy: { decidedAt: 'desc' },
    });
    // NB: dateFilter влияет только на агрегаты (totals/lists). Пагинация и
    // долгосрочные тренды по проектам с тысячами движений требуют отдельного
    // PaymentReport-эндпоинта (S+).

    // Подгружаем имена юзеров одной выборкой по уникальным ID.
    const userIds = new Set<string>();
    advances.forEach((p) => userIds.add(p.toUserId));
    distributions.forEach((p) => userIds.add(p.toUserId));
    approvedSp.forEach((sp) => userIds.add(sp.byUserId));
    rejectedSp.forEach((sp) => userIds.add(sp.byUserId));
    materialReqs.forEach((r) => userIds.add(r.createdById));
    pendingMaterialReqs.forEach((r) => userIds.add(r.createdById));
    rejectedMaterialReqs.forEach((r) => userIds.add(r.createdById));
    const users =
      userIds.size > 0
        ? await this.prisma.user.findMany({
            where: { id: { in: [...userIds] } },
            select: { id: true, firstName: true, lastName: true },
          })
        : [];
    const userById = new Map(users.map((u) => [u.id, u]));

    const totalAdvances = advances.reduce(
      (acc, p) => acc.plus(Money.ofKopeks(p.amount)),
      Money.zero(),
    );
    const totalDistributed = distributions.reduce(
      (acc, p) => acc.plus(Money.ofKopeks(p.amount)),
      Money.zero(),
    );
    const totalApprovedSp = approvedSp.reduce(
      (acc, sp) => acc.plus(Money.ofKopeks(sp.amount)),
      Money.zero(),
    );
    const totalMaterials = materialReqs.reduce(
      (acc, r) =>
        acc.plus(
          r.items.reduce(
            (inner, it) => inner.plus(Money.ofKopeks(it.totalPrice ?? BigInt(0))),
            Money.zero(),
          ),
        ),
      Money.zero(),
    );

    const fmtUser = (id: string) => {
      const u = userById.get(id);
      if (!u) return '—';
      return `${u.firstName ?? ''} ${u.lastName ?? ''}`.trim() || '—';
    };

    return {
      advances: advances.map((p) => ({
        id: p.id,
        toUserId: p.toUserId,
        toUserName: fmtUser(p.toUserId),
        amount: Number(p.amount),
        createdAt: p.createdAt,
      })),
      distributions: distributions.map((p) => ({
        id: p.id,
        parentPaymentId: p.parentPaymentId,
        fromUserId: p.fromUserId,
        toUserId: p.toUserId,
        toUserName: fmtUser(p.toUserId),
        amount: Number(p.amount),
        createdAt: p.createdAt,
      })),
      approvedSelfpurchases: approvedSp.map((sp) => ({
        id: sp.id,
        byUserId: sp.byUserId,
        byUserName: fmtUser(sp.byUserId),
        amount: Number(sp.amount),
        comment: sp.comment,
        decidedAt: sp.decidedAt,
      })),
      materialPurchases: materialReqs.map((r) => {
        const totalSpent = r.items.reduce(
          (acc, it) => acc.plus(Money.ofKopeks(it.totalPrice ?? BigInt(0))),
          Money.zero(),
        );
        return {
          requestId: r.id,
          title: r.title ?? 'Запрос материалов',
          totalSpent: Number(totalSpent.kopeks()),
          itemCount: r.items.length,
          boughtBy: r.recipient as 'customer' | 'foreman',
          requestedByName: fmtUser(r.createdById),
        };
      }),
      pendingMaterials: pendingMaterialReqs.map((r) => {
        const estimated = r.items.reduce(
          (acc, it) => acc.plus(Money.ofKopeks(it.totalPrice ?? BigInt(0))),
          Money.zero(),
        );
        return {
          requestId: r.id,
          title: r.title ?? 'Запрос материалов',
          estimatedTotal: Number(estimated.kopeks()),
          itemCount: r.items.length,
          requestedByName: fmtUser(r.createdById),
          createdAt: r.createdAt,
        };
      }),
      rejectedMaterials: rejectedMaterialReqs.map((r) => {
        const estimated = r.items.reduce(
          (acc, it) => acc.plus(Money.ofKopeks(it.totalPrice ?? BigInt(0))),
          Money.zero(),
        );
        return {
          requestId: r.id,
          title: r.title ?? 'Запрос материалов',
          estimatedTotal: Number(estimated.kopeks()),
          itemCount: r.items.length,
          requestedByName: fmtUser(r.createdById),
          decidedAt: r.updatedAt,
        };
      }),
      rejectedSelfpurchases: rejectedSp.map((sp) => ({
        id: sp.id,
        byUserName: fmtUser(sp.byUserId),
        amount: Number(sp.amount),
        comment: sp.comment,
        decidedAt: sp.decidedAt,
      })),
      totals: {
        advances: Number(totalAdvances.kopeks()),
        distributed: Number(totalDistributed.kopeks()),
        undistributed: Number(totalAdvances.minus(totalDistributed).kopeks()),
        approvedSelfpurchases: Number(totalApprovedSp.kopeks()),
        materials: Number(totalMaterials.kopeks()),
      },
    };
  }

  /**
   * Срез money-flow для бригадира: только то, в чём он сторона.
   * - advances: где он `toUserId` (полученные от заказчика)
   * - distributions: где он `fromUserId` (выплаченные мастерам)
   * - approvedSelfpurchases: его собственные одобренные самозакупы
   * - materialPurchases: запросы материалов его этапов
   */
  private async getForemanMoneyFlow(
    projectId: string,
    foremanUserId: string,
    range?: { from?: Date; to?: Date },
  ): Promise<MoneyFlowDTO> {
    const dateFilter =
      range && (range.from || range.to)
        ? {
            ...(range.from ? { gte: range.from } : {}),
            ...(range.to ? { lte: range.to } : {}),
          }
        : undefined;

    const myStages = await this.prisma.stage.findMany({
      where: { projectId, foremanIds: { has: foremanUserId } },
      select: { id: true },
    });
    const myStageIds = myStages.map((s) => s.id);

    const advances = await this.prisma.payment.findMany({
      where: {
        projectId,
        kind: 'advance',
        toUserId: foremanUserId,
        ...(dateFilter ? { createdAt: dateFilter } : {}),
      },
      orderBy: { createdAt: 'desc' },
    });
    const distributions = await this.prisma.payment.findMany({
      where: {
        projectId,
        kind: 'distribution',
        fromUserId: foremanUserId,
        ...(dateFilter ? { createdAt: dateFilter } : {}),
      },
      orderBy: { createdAt: 'desc' },
    });
    const approvedSp = await this.prisma.selfPurchase.findMany({
      where: {
        projectId,
        status: 'approved',
        byRole: 'foreman',
        byUserId: foremanUserId,
        ...(dateFilter ? { decidedAt: dateFilter } : {}),
      },
      orderBy: { decidedAt: 'desc' },
    });
    const materialReqs =
      myStageIds.length === 0
        ? []
        : await this.prisma.materialRequest.findMany({
            where: {
              projectId,
              stageId: { in: myStageIds },
              // «Согласовано» = open.
              status: 'open',
              ...(dateFilter ? { finalizedAt: dateFilter } : {}),
            },
            include: { items: true },
            orderBy: { createdAt: 'desc' },
          });
    const pendingMaterialReqs =
      myStageIds.length === 0
        ? []
        : await this.prisma.materialRequest.findMany({
            where: {
              projectId,
              stageId: { in: myStageIds },
              status: 'pending_approval',
              ...(dateFilter ? { createdAt: dateFilter } : {}),
            },
            include: { items: true },
            orderBy: { createdAt: 'desc' },
          });
    const rejectedMaterialReqs =
      myStageIds.length === 0
        ? []
        : await this.prisma.materialRequest.findMany({
            where: {
              projectId,
              stageId: { in: myStageIds },
              status: 'cancelled',
              ...(dateFilter ? { updatedAt: dateFilter } : {}),
            },
            include: { items: true },
            orderBy: { updatedAt: 'desc' },
          });
    const rejectedSp = await this.prisma.selfPurchase.findMany({
      where: {
        projectId,
        status: 'rejected',
        byUserId: foremanUserId,
        ...(dateFilter ? { decidedAt: dateFilter } : {}),
      },
      orderBy: { decidedAt: 'desc' },
    });

    const userIds = new Set<string>();
    advances.forEach((p) => userIds.add(p.fromUserId));
    distributions.forEach((p) => userIds.add(p.toUserId));
    materialReqs.forEach((r) => userIds.add(r.createdById));
    pendingMaterialReqs.forEach((r) => userIds.add(r.createdById));
    rejectedMaterialReqs.forEach((r) => userIds.add(r.createdById));
    const users =
      userIds.size > 0
        ? await this.prisma.user.findMany({
            where: { id: { in: [...userIds] } },
            select: { id: true, firstName: true, lastName: true },
          })
        : [];
    const userById = new Map(users.map((u) => [u.id, u]));
    const fmtUser = (id: string) => {
      const u = userById.get(id);
      if (!u) return '—';
      return `${u.firstName ?? ''} ${u.lastName ?? ''}`.trim() || '—';
    };

    const sumAll = (rows: typeof advances) =>
      rows.reduce((acc, p) => acc.plus(Money.ofKopeks(p.amount)), Money.zero());

    const totalAdvances = sumAll(advances);
    const totalDistributed = sumAll(distributions);
    const totalApprovedSp = approvedSp.reduce(
      (acc, sp) => acc.plus(Money.ofKopeks(sp.amount)),
      Money.zero(),
    );
    const totalMaterials = materialReqs.reduce(
      (acc, r) =>
        acc.plus(
          r.items.reduce(
            (inner, it) => inner.plus(Money.ofKopeks(it.totalPrice ?? BigInt(0))),
            Money.zero(),
          ),
        ),
      Money.zero(),
    );

    return {
      advances: advances.map((p) => ({
        id: p.id,
        toUserId: p.toUserId,
        toUserName: fmtUser(p.fromUserId),
        amount: Number(p.amount),
        createdAt: p.createdAt,
      })),
      distributions: distributions.map((p) => ({
        id: p.id,
        parentPaymentId: p.parentPaymentId,
        fromUserId: p.fromUserId,
        toUserId: p.toUserId,
        toUserName: fmtUser(p.toUserId),
        amount: Number(p.amount),
        createdAt: p.createdAt,
      })),
      approvedSelfpurchases: approvedSp.map((sp) => ({
        id: sp.id,
        byUserId: sp.byUserId,
        byUserName: fmtUser(sp.byUserId) === '—' ? 'Я' : fmtUser(sp.byUserId),
        amount: Number(sp.amount),
        comment: sp.comment,
        decidedAt: sp.decidedAt,
      })),
      materialPurchases: materialReqs.map((r) => {
        const totalSpent = r.items.reduce(
          (acc, it) => acc.plus(Money.ofKopeks(it.totalPrice ?? BigInt(0))),
          Money.zero(),
        );
        return {
          requestId: r.id,
          title: r.title ?? 'Запрос материалов',
          totalSpent: Number(totalSpent.kopeks()),
          itemCount: r.items.length,
          boughtBy: r.recipient as 'customer' | 'foreman',
          requestedByName: fmtUser(r.createdById),
        };
      }),
      pendingMaterials: pendingMaterialReqs.map((r) => {
        const estimated = r.items.reduce(
          (acc, it) => acc.plus(Money.ofKopeks(it.totalPrice ?? BigInt(0))),
          Money.zero(),
        );
        return {
          requestId: r.id,
          title: r.title ?? 'Запрос материалов',
          estimatedTotal: Number(estimated.kopeks()),
          itemCount: r.items.length,
          requestedByName: fmtUser(r.createdById),
          createdAt: r.createdAt,
        };
      }),
      rejectedMaterials: rejectedMaterialReqs.map((r) => {
        const estimated = r.items.reduce(
          (acc, it) => acc.plus(Money.ofKopeks(it.totalPrice ?? BigInt(0))),
          Money.zero(),
        );
        return {
          requestId: r.id,
          title: r.title ?? 'Запрос материалов',
          estimatedTotal: Number(estimated.kopeks()),
          itemCount: r.items.length,
          requestedByName: fmtUser(r.createdById),
          decidedAt: r.updatedAt,
        };
      }),
      rejectedSelfpurchases: rejectedSp.map((sp) => ({
        id: sp.id,
        byUserName: fmtUser(sp.byUserId) === '—' ? 'Я' : fmtUser(sp.byUserId),
        amount: Number(sp.amount),
        comment: sp.comment,
        decidedAt: sp.decidedAt,
      })),
      // Касса бригадира — агрегированный остаток для распределения мастерам.
      // available может быть отрицательным (см. JSDoc ForemanWallet).
      wallet: {
        advancesReceived: Number(totalAdvances.kopeks()),
        distributed: Number(totalDistributed.kopeks()),
        available: Number(totalAdvances.minus(totalDistributed).kopeks()),
      },
      totals: {
        advances: Number(totalAdvances.kopeks()),
        distributed: Number(totalDistributed.kopeks()),
        undistributed: Number(totalAdvances.minus(totalDistributed).kopeks()),
        approvedSelfpurchases: Number(totalApprovedSp.kopeks()),
        materials: Number(totalMaterials.kopeks()),
      },
    };
  }

  private stageVisibleTo(
    viewer: BudgetViewerContext,
    stageId: string,
    stageForemanIds: string[],
  ): boolean {
    if (viewer.isOwner) return true;
    if (viewer.membershipRole === 'representative') return true;
    if (viewer.membershipRole === 'foreman') return stageForemanIds.includes(viewer.userId);
    if (viewer.membershipRole === 'master') {
      return (viewer.assignedStageIds ?? []).includes(stageId);
    }
    return false;
  }

  private bucket(planned: Money, spent: Money): BudgetBucket {
    return {
      planned: Number(planned.kopeks()),
      spent: Number(spent.kopeks()),
      remaining: Number(planned.minus(spent).kopeks()),
    };
  }
}
