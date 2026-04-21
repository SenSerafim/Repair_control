import { BudgetCalculator } from './budget-calculator';
import { PrismaService } from '@app/common';

const mkPrisma = () => {
  const state = {
    project: null as any,
    stages: [] as any[],
    payments: [] as any[],
    materialRequests: [] as any[],
    selfPurchases: [] as any[],
  };
  const prisma: any = {
    project: {
      findUnique: jest.fn(({ where, include }: any) => {
        if (!state.project || state.project.id !== where.id) return null;
        if (include?.stages) return { ...state.project, stages: state.stages };
        return state.project;
      }),
    },
    stage: {
      findUnique: jest.fn(({ where }: any) => state.stages.find((s) => s.id === where.id) ?? null),
    },
    payment: {
      findMany: jest.fn(({ where }: any) =>
        state.payments.filter((p) => {
          if (where.projectId && p.projectId !== where.projectId) return false;
          if (where.stageId && p.stageId !== where.stageId) return false;
          if (where.status?.in && !where.status.in.includes(p.status)) return false;
          if (where.kind && p.kind !== where.kind) return false;
          return true;
        }),
      ),
    },
    materialRequest: {
      findMany: jest.fn(({ where, include }: any) => {
        const filtered = state.materialRequests.filter((r) => {
          if (where.projectId && r.projectId !== where.projectId) return false;
          if (where.stageId && r.stageId !== where.stageId) return false;
          if (where.status?.in && !where.status.in.includes(r.status)) return false;
          if (where.finalizedAt?.not === null && !r.finalizedAt) return false;
          return true;
        });
        if (include?.items) {
          return filtered.map((r) => ({
            ...r,
            items: (r.items ?? []).filter((it: any) => it.isBought),
          }));
        }
        return filtered;
      }),
    },
    selfPurchase: {
      findMany: jest.fn(({ where }: any) =>
        state.selfPurchases.filter((sp) => {
          if (where.projectId && sp.projectId !== where.projectId) return false;
          if (where.stageId && sp.stageId !== where.stageId) return false;
          if (where.status && sp.status !== where.status) return false;
          return true;
        }),
      ),
    },
  };
  return { prisma: prisma as unknown as PrismaService, state };
};

describe('BudgetCalculator', () => {
  it('getProjectBudget: план/потрачено/остаток корректны для owner', async () => {
    const { prisma, state } = mkPrisma();
    state.project = { id: 'p1', ownerId: 'cust1' };
    state.stages = [
      {
        id: 's1',
        projectId: 'p1',
        title: 'Электрика',
        orderIndex: 0,
        workBudget: BigInt(500_000_00),
        materialsBudget: BigInt(100_000_00),
        foremanIds: ['foreman1'],
      },
      {
        id: 's2',
        projectId: 'p1',
        title: 'Плитка',
        orderIndex: 1,
        workBudget: BigInt(200_000_00),
        materialsBudget: BigInt(80_000_00),
        foremanIds: ['foreman1'],
      },
    ];
    state.payments = [
      {
        id: 'pay1',
        projectId: 'p1',
        stageId: 's1',
        kind: 'advance',
        status: 'confirmed',
        amount: BigInt(300_000_00),
        resolvedAmount: null,
      },
    ];
    state.materialRequests = [
      {
        id: 'mr1',
        projectId: 'p1',
        stageId: 's1',
        status: 'bought',
        finalizedAt: new Date(),
        items: [{ isBought: true, totalPrice: BigInt(50_000_00) }],
      },
    ];

    const calc = new BudgetCalculator(prisma);
    const b = await calc.getProjectBudget('p1', {
      userId: 'cust1',
      isOwner: true,
    });
    expect(b.work.planned).toBe(700_000_00);
    expect(b.work.spent).toBe(300_000_00);
    expect(b.work.remaining).toBe(400_000_00);
    expect(b.materials.planned).toBe(180_000_00);
    expect(b.materials.spent).toBe(50_000_00);
    expect(b.total.planned).toBe(880_000_00);
    expect(b.total.spent).toBe(350_000_00);
    expect(b.stages).toHaveLength(2);
    expect(b.stages[0].work.spent).toBe(300_000_00);
  });

  it('master видит только назначенные ему стадии', async () => {
    const { prisma, state } = mkPrisma();
    state.project = { id: 'p1', ownerId: 'cust1' };
    state.stages = [
      {
        id: 's1',
        projectId: 'p1',
        title: 'A',
        orderIndex: 0,
        workBudget: BigInt(100),
        materialsBudget: BigInt(0),
        foremanIds: [],
      },
      {
        id: 's2',
        projectId: 'p1',
        title: 'B',
        orderIndex: 1,
        workBudget: BigInt(200),
        materialsBudget: BigInt(0),
        foremanIds: [],
      },
    ];
    state.payments = [];
    state.materialRequests = [];

    const calc = new BudgetCalculator(prisma);
    const b = await calc.getProjectBudget('p1', {
      userId: 'm1',
      isOwner: false,
      membershipRole: 'master',
      assignedStageIds: ['s1'],
    });
    expect(b.stages).toHaveLength(1);
    expect(b.stages[0].stageId).toBe('s1');
  });

  it('foreman видит только свои стадии (по foremanIds)', async () => {
    const { prisma, state } = mkPrisma();
    state.project = { id: 'p1', ownerId: 'cust1' };
    state.stages = [
      {
        id: 's1',
        projectId: 'p1',
        title: 'A',
        orderIndex: 0,
        workBudget: BigInt(100),
        materialsBudget: BigInt(0),
        foremanIds: ['f1'],
      },
      {
        id: 's2',
        projectId: 'p1',
        title: 'B',
        orderIndex: 1,
        workBudget: BigInt(200),
        materialsBudget: BigInt(0),
        foremanIds: ['f2'],
      },
    ];
    state.payments = [];
    state.materialRequests = [];
    const calc = new BudgetCalculator(prisma);
    const b = await calc.getProjectBudget('p1', {
      userId: 'f1',
      isOwner: false,
      membershipRole: 'foreman',
    });
    expect(b.stages).toHaveLength(1);
    expect(b.stages[0].stageId).toBe('s1');
  });

  it('approved SelfPurchase суммируется в materials.spent', async () => {
    const { prisma, state } = mkPrisma();
    state.project = { id: 'p1', ownerId: 'cust1' };
    state.stages = [
      {
        id: 's1',
        projectId: 'p1',
        title: 'A',
        orderIndex: 0,
        workBudget: BigInt(0),
        materialsBudget: BigInt(100_000_00),
        foremanIds: [],
      },
    ];
    state.payments = [];
    state.materialRequests = [];
    state.selfPurchases = [
      { id: 'sp1', projectId: 'p1', stageId: 's1', status: 'approved', amount: BigInt(8_000_00) },
      { id: 'sp2', projectId: 'p1', stageId: 's1', status: 'rejected', amount: BigInt(10_000_00) },
    ];
    const calc = new BudgetCalculator(prisma);
    const b = await calc.getProjectBudget('p1', { userId: 'cust1', isOwner: true });
    expect(b.materials.spent).toBe(8_000_00);
    expect(b.stages[0].materials.spent).toBe(8_000_00);
  });

  it('resolvedAmount используется вместо amount для resolved', async () => {
    const { prisma, state } = mkPrisma();
    state.project = { id: 'p1', ownerId: 'cust1' };
    state.stages = [
      {
        id: 's1',
        projectId: 'p1',
        title: 'A',
        orderIndex: 0,
        workBudget: BigInt(100_000_00),
        materialsBudget: BigInt(0),
        foremanIds: [],
      },
    ];
    state.payments = [
      {
        id: 'pay1',
        projectId: 'p1',
        stageId: 's1',
        kind: 'advance',
        status: 'resolved',
        amount: BigInt(100_000_00),
        resolvedAmount: BigInt(80_000_00),
      },
    ];
    state.materialRequests = [];
    const calc = new BudgetCalculator(prisma);
    const b = await calc.getProjectBudget('p1', { userId: 'cust1', isOwner: true });
    expect(b.work.spent).toBe(80_000_00);
  });
});
