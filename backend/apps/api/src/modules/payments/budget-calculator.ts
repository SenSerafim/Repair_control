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
  status: string;
  createdAt: Date;
  confirmedAt: Date | null;
}

export interface DistributionFlow {
  id: string;
  parentPaymentId: string | null;
  fromUserId: string;
  toUserId: string;
  toUserName: string;
  amount: number;
  status: string;
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
  totals: MoneyFlowTotals;
}

/**
 * BudgetCalculator — dynamic view бюджета (ТЗ §4): план + потрачено + остаток.
 *
 * Spent = sum(confirmed+resolved payments by category)
 *       + sum(finalized material items isBought=true)
 */
@Injectable()
export class BudgetCalculator {
  constructor(private readonly prisma: PrismaService) {}

  async getProjectBudget(
    projectId: string,
    viewer: BudgetViewerContext,
  ): Promise<ProjectBudgetDTO> {
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
      };
    }

    const payments = await this.prisma.payment.findMany({
      where: {
        projectId,
        status: { in: ['confirmed', 'resolved'] },
        kind: 'advance',
      },
    });
    const materialRequests = await this.prisma.materialRequest.findMany({
      where: {
        projectId,
        status: { in: ['bought', 'partially_bought', 'delivered', 'resolved'] },
        finalizedAt: { not: null },
      },
      include: { items: { where: { isBought: true } } },
    });
    const selfPurchases = await this.prisma.selfPurchase.findMany({
      where: { projectId, status: 'approved' },
    });

    const workSpent = payments.reduce(
      (acc, p) => acc.plus(Money.ofKopeks(p.resolvedAmount ?? p.amount)),
      Money.zero(),
    );
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
    const materialsSpent = materialsFromRequests.plus(materialsFromSelfPurchases);

    const workPlanned = project.stages.reduce(
      (acc, s) => acc.plus(Money.ofKopeks(s.workBudget)),
      Money.zero(),
    );
    const materialsPlanned = project.stages.reduce(
      (acc, s) => acc.plus(Money.ofKopeks(s.materialsBudget)),
      Money.zero(),
    );

    const stages: StageBudgetDTO[] = project.stages
      .filter((s) => this.stageVisibleTo(viewer, s.id, s.foremanIds))
      .map((s) => {
        const stageWorkSpent = payments
          .filter((p) => p.stageId === s.id)
          .reduce((acc, p) => acc.plus(Money.ofKopeks(p.resolvedAmount ?? p.amount)), Money.zero());
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
        const stageMaterialsSpent = stageMaterialsFromReq.plus(stageMaterialsFromSp);
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

    return {
      work: this.bucket(workPlanned, workSpent),
      materials: this.bucket(materialsPlanned, materialsSpent),
      total: this.bucket(workPlanned.plus(materialsPlanned), workSpent.plus(materialsSpent)),
      stages,
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
      where: { stageId, status: { in: ['confirmed', 'resolved'] } },
    });
    const materialRequests = await this.prisma.materialRequest.findMany({
      where: {
        stageId,
        status: { in: ['bought', 'partially_bought', 'delivered', 'resolved'] },
        finalizedAt: { not: null },
      },
      include: { items: { where: { isBought: true } } },
    });
    const stageSelfPurchases = await this.prisma.selfPurchase.findMany({
      where: { stageId, status: 'approved' },
    });
    const workSpent = payments.reduce(
      (acc, p) => acc.plus(Money.ofKopeks(p.resolvedAmount ?? p.amount)),
      Money.zero(),
    );
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
   * и закупки материалов. Доступно только owner / representative.canSeeBudget.
   * Для master/foreman/outsider — пустой объект.
   */
  async getMoneyFlow(projectId: string, viewer: BudgetViewerContext): Promise<MoneyFlowDTO> {
    const empty: MoneyFlowDTO = {
      advances: [],
      distributions: [],
      approvedSelfpurchases: [],
      materialPurchases: [],
      totals: {
        advances: 0,
        distributed: 0,
        undistributed: 0,
        approvedSelfpurchases: 0,
        materials: 0,
      },
    };
    const allowed = viewer.isOwner || viewer.canSeeBudget === true;
    if (!allowed) return empty;

    const advances = await this.prisma.payment.findMany({
      where: { projectId, kind: 'advance' },
      orderBy: { createdAt: 'desc' },
    });
    const distributions = await this.prisma.payment.findMany({
      where: { projectId, kind: 'distribution' },
      orderBy: { createdAt: 'desc' },
    });
    const approvedSp = await this.prisma.selfPurchase.findMany({
      where: { projectId, status: 'approved', byRole: 'foreman' },
      orderBy: { decidedAt: 'desc' },
    });
    const materialReqs = await this.prisma.materialRequest.findMany({
      where: {
        projectId,
        status: { in: ['bought', 'partially_bought', 'delivered', 'resolved'] },
        finalizedAt: { not: null },
      },
      include: { items: { where: { isBought: true } } },
      orderBy: { createdAt: 'desc' },
    });

    // Подгружаем имена юзеров одной выборкой по уникальным ID.
    const userIds = new Set<string>();
    advances.forEach((p) => userIds.add(p.toUserId));
    distributions.forEach((p) => userIds.add(p.toUserId));
    approvedSp.forEach((sp) => userIds.add(sp.byUserId));
    const users =
      userIds.size > 0
        ? await this.prisma.user.findMany({
            where: { id: { in: [...userIds] } },
            select: { id: true, firstName: true, lastName: true },
          })
        : [];
    const userById = new Map(users.map((u) => [u.id, u]));

    const totalAdvances = advances.reduce(
      (acc, p) =>
        p.status === 'confirmed' || p.status === 'resolved'
          ? acc.plus(Money.ofKopeks(p.resolvedAmount ?? p.amount))
          : acc,
      Money.zero(),
    );
    const totalDistributed = distributions.reduce(
      (acc, p) =>
        p.status === 'confirmed' || p.status === 'resolved'
          ? acc.plus(Money.ofKopeks(p.resolvedAmount ?? p.amount))
          : acc,
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
        amount: Number(p.resolvedAmount ?? p.amount),
        status: p.status,
        createdAt: p.createdAt,
        confirmedAt: p.confirmedAt,
      })),
      distributions: distributions.map((p) => ({
        id: p.id,
        parentPaymentId: p.parentPaymentId,
        fromUserId: p.fromUserId,
        toUserId: p.toUserId,
        toUserName: fmtUser(p.toUserId),
        amount: Number(p.resolvedAmount ?? p.amount),
        status: p.status,
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
        };
      }),
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
