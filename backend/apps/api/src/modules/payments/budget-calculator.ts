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

    const workSpent = payments.reduce(
      (acc, p) => acc.plus(Money.ofKopeks(p.resolvedAmount ?? p.amount)),
      Money.zero(),
    );
    const materialsSpent = materialRequests.reduce(
      (acc, r) =>
        acc.plus(
          r.items.reduce(
            (inner, it) => inner.plus(Money.ofKopeks(it.totalPrice ?? BigInt(0))),
            Money.zero(),
          ),
        ),
      Money.zero(),
    );

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
        const stageMaterialsSpent = materialRequests
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
    const workSpent = payments.reduce(
      (acc, p) => acc.plus(Money.ofKopeks(p.resolvedAmount ?? p.amount)),
      Money.zero(),
    );
    const materialsSpent = materialRequests.reduce(
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
