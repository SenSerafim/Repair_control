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
      findMany: jest.fn(({ where }: any) =>
        state.stages.filter((s) => {
          if (where.projectId && s.projectId !== where.projectId) return false;
          if (where.id?.in && !where.id.in.includes(s.id)) return false;
          if (where.foremanIds?.has && !(s.foremanIds ?? []).includes(where.foremanIds.has)) {
            return false;
          }
          return true;
        }),
      ),
    },
    payment: {
      findMany: jest.fn(({ where }: any) =>
        state.payments.filter((p) => {
          if (where.projectId && p.projectId !== where.projectId) return false;
          if (where.stageId && p.stageId !== where.stageId) return false;
          if (where.status?.in && !where.status.in.includes(p.status)) return false;
          if (where.kind && p.kind !== where.kind) return false;
          if (where.fromUserId && p.fromUserId !== where.fromUserId) return false;
          if (where.toUserId && p.toUserId !== where.toUserId) return false;
          if (where.OR) {
            const matchesOr = (where.OR as any[]).some((or) => {
              if (or.toUserId && p.toUserId === or.toUserId) return true;
              if (or.fromUserId && p.fromUserId === or.fromUserId) return true;
              return false;
            });
            if (!matchesOr) return false;
          }
          if (where.createdAt) {
            if (where.createdAt.gte && p.createdAt < where.createdAt.gte) return false;
            if (where.createdAt.lte && p.createdAt > where.createdAt.lte) return false;
          }
          return true;
        }),
      ),
    },
    materialRequest: {
      findMany: jest.fn(({ where, include }: any) => {
        const filtered = state.materialRequests.filter((r) => {
          if (where.projectId && r.projectId !== where.projectId) return false;
          if (typeof where.stageId === 'string' && r.stageId !== where.stageId) return false;
          if (where.stageId?.in && !where.stageId.in.includes(r.stageId)) return false;
          if (typeof where.status === 'string' && r.status !== where.status) return false;
          if (where.status?.in && !where.status.in.includes(r.status)) return false;
          if (where.finalizedAt) {
            if (where.finalizedAt.gte && (!r.finalizedAt || r.finalizedAt < where.finalizedAt.gte))
              return false;
            if (where.finalizedAt.lte && (!r.finalizedAt || r.finalizedAt > where.finalizedAt.lte))
              return false;
          }
          if (where.createdAt) {
            if (where.createdAt.gte && r.createdAt < where.createdAt.gte) return false;
            if (where.createdAt.lte && r.createdAt > where.createdAt.lte) return false;
          }
          if (where.updatedAt) {
            const upd = r.updatedAt ?? r.createdAt;
            if (where.updatedAt.gte && upd < where.updatedAt.gte) return false;
            if (where.updatedAt.lte && upd > where.updatedAt.lte) return false;
          }
          return true;
        });
        if (include?.items) {
          return filtered.map((r) => ({ ...r, items: r.items ?? [] }));
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
          if (where.byRole && sp.byRole !== where.byRole) return false;
          if (where.byUserId && sp.byUserId !== where.byUserId) return false;
          if (where.decidedAt) {
            if (where.decidedAt.gte && (!sp.decidedAt || sp.decidedAt < where.decidedAt.gte))
              return false;
            if (where.decidedAt.lte && (!sp.decidedAt || sp.decidedAt > where.decidedAt.lte))
              return false;
          }
          return true;
        }),
      ),
    },
    user: {
      findMany: jest.fn(() => []),
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
        amount: BigInt(300_000_00),
      },
    ];
    state.materialRequests = [
      {
        id: 'mr1',
        projectId: 'p1',
        stageId: 's1',
        status: 'open',
        finalizedAt: new Date(),
        items: [{ totalPrice: BigInt(50_000_00) }],
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

  it('master видит master-view (свои выплаты, без общего бюджета)', async () => {
    // 2026-05 рефактор: master больше не видит StageBudget с planned/spent;
    // вместо этого ProjectBudget.earnings содержит его персональные выплаты.
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
    expect(b.viewerKind).toBe('master');
    expect(b.stages).toEqual([]);
    expect(b.work.planned).toBe(0);
    expect(b.earnings).toEqual([]);
  });

  it('owner видит fallback на Project.workBudget когда у этапов workBudget=0', async () => {
    // Воспроизведение бага: wizard заносит бюджет на Project.workBudget,
    // но создаёт стадии с workBudget=0. Бэк должен делать fallback на
    // projectWorkBigInt — иначе шапка «Общий бюджет» показывает 0.
    const { prisma, state } = mkPrisma();
    state.project = {
      id: 'p1',
      ownerId: 'cust1',
      workBudget: BigInt(1_000_000_00),
      materialsBudget: BigInt(500_000_00),
    };
    state.stages = [
      {
        id: 's1',
        projectId: 'p1',
        title: 'A',
        orderIndex: 0,
        workBudget: BigInt(0),
        materialsBudget: BigInt(0),
        foremanIds: [],
      },
    ];
    state.payments = [];
    state.materialRequests = [];
    state.selfPurchases = [];
    const calc = new BudgetCalculator(prisma);
    const b = await calc.getProjectBudget('p1', {
      userId: 'cust1',
      isOwner: true,
      membershipRole: 'customer',
    });
    expect(b.work.planned).toBe(1_000_000_00);
    expect(b.materials.planned).toBe(500_000_00);
    expect(b.total.planned).toBe(1_500_000_00);
    expect(b.viewerKind).toBe('owner');
  });

  it('foreman + zero-budget стадии: noStageBudget=true при наличии Project.workBudget', async () => {
    // Сценарий бага: бригадир видит свои этапы, но они нулевые → шапка = 0.
    // Бэк возвращает noStageBudget:true, чтобы мобайл показал объясняющий баннер.
    const { prisma, state } = mkPrisma();
    state.project = {
      id: 'p1',
      ownerId: 'cust1',
      workBudget: BigInt(1_000_000_00),
      materialsBudget: BigInt(500_000_00),
    };
    state.stages = [
      {
        id: 's1',
        projectId: 'p1',
        title: 'A',
        orderIndex: 0,
        workBudget: BigInt(0),
        materialsBudget: BigInt(0),
        foremanIds: ['f1'],
      },
    ];
    state.payments = [];
    state.materialRequests = [];
    state.selfPurchases = [];
    const calc = new BudgetCalculator(prisma);
    const b = await calc.getProjectBudget('p1', {
      userId: 'f1',
      isOwner: false,
      membershipRole: 'foreman',
    });
    expect(b.work.planned).toBe(0);
    expect(b.noStageBudget).toBe(true);
  });

  it('foreman + распределённый бюджет на стадиях: noStageBudget отсутствует', async () => {
    const { prisma, state } = mkPrisma();
    state.project = {
      id: 'p1',
      ownerId: 'cust1',
      workBudget: BigInt(1_000_000_00),
      materialsBudget: BigInt(0),
    };
    state.stages = [
      {
        id: 's1',
        projectId: 'p1',
        title: 'A',
        orderIndex: 0,
        workBudget: BigInt(500_000_00),
        materialsBudget: BigInt(0),
        foremanIds: ['f1'],
      },
    ];
    state.payments = [];
    state.materialRequests = [];
    state.selfPurchases = [];
    const calc = new BudgetCalculator(prisma);
    const b = await calc.getProjectBudget('p1', {
      userId: 'f1',
      isOwner: false,
      membershipRole: 'foreman',
    });
    expect(b.work.planned).toBe(500_000_00);
    expect(b.noStageBudget).toBeUndefined();
  });

  it('foreman money-flow: только свои входящие авансы и исходящие распределения', async () => {
    const { prisma, state } = mkPrisma();
    state.project = { id: 'p1', ownerId: 'cust1' };
    state.stages = [
      {
        id: 's1',
        projectId: 'p1',
        title: 'A',
        orderIndex: 0,
        workBudget: BigInt(0),
        materialsBudget: BigInt(0),
        foremanIds: ['f1'],
      },
    ];
    state.payments = [
      {
        id: 'adv-f1',
        projectId: 'p1',
        kind: 'advance',
        amount: BigInt(50_000_00),
        fromUserId: 'cust1',
        toUserId: 'f1',
        createdAt: new Date('2026-01-10'),
      },
      {
        id: 'adv-other',
        projectId: 'p1',
        kind: 'advance',
        amount: BigInt(80_000_00),
        fromUserId: 'cust1',
        toUserId: 'f2',
        createdAt: new Date('2026-01-12'),
      },
      {
        id: 'dist-f1',
        projectId: 'p1',
        kind: 'distribution',
        amount: BigInt(20_000_00),
        fromUserId: 'f1',
        toUserId: 'm1',
        parentPaymentId: 'adv-f1',
        createdAt: new Date('2026-01-15'),
      },
    ];
    state.materialRequests = [];
    state.selfPurchases = [];
    const calc = new BudgetCalculator(prisma);
    const flow = await calc.getMoneyFlow('p1', {
      userId: 'f1',
      isOwner: false,
      membershipRole: 'foreman',
      canSeeBudget: false,
    });
    expect(flow.advances.map((a) => a.id)).toEqual(['adv-f1']);
    expect(flow.distributions.map((d) => d.id)).toEqual(['dist-f1']);
  });

  it('foreman видит только свои стадии (по foremanIds) и итоги только по ним (ТЗ §6)', async () => {
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
    // 2026-05 рефактор: top-level work.planned равняется только сумме видимых стадий.
    expect(b.work.planned).toBe(100);
    expect(b.viewerKind).toBe('foreman');
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
      // foreman→customer approved → попадает в budget.
      {
        id: 'sp1',
        projectId: 'p1',
        stageId: 's1',
        status: 'approved',
        byRole: 'foreman',
        amount: BigInt(8_000_00),
      },
      // foreman rejected → исключён.
      {
        id: 'sp2',
        projectId: 'p1',
        stageId: 's1',
        status: 'rejected',
        byRole: 'foreman',
        amount: BigInt(10_000_00),
      },
      // master→foreman approved (без forwarding) → НЕ должен учитываться,
      // т.к. ТЗ §4.3 требует одобрения заказчиком.
      {
        id: 'sp3',
        projectId: 'p1',
        stageId: 's1',
        status: 'approved',
        byRole: 'master',
        amount: BigInt(15_000_00),
      },
    ];
    const calc = new BudgetCalculator(prisma);
    const b = await calc.getProjectBudget('p1', { userId: 'cust1', isOwner: true });
    expect(b.materials.spent).toBe(8_000_00);
    expect(b.stages[0].materials.spent).toBe(8_000_00);
  });

  it('getMoneyFlow: date-range фильтрует advances по createdAt', async () => {
    const { prisma, state } = mkPrisma();
    state.project = { id: 'p1', ownerId: 'cust1' };
    state.stages = [];
    state.materialRequests = [];
    state.selfPurchases = [];
    state.payments = [
      {
        id: 'pay-jan',
        projectId: 'p1',
        kind: 'advance',
        amount: BigInt(50_000_00),
        toUserId: 'foreman1',
        createdAt: new Date('2025-01-15'),
      },
      {
        id: 'pay-mar',
        projectId: 'p1',
        kind: 'advance',
        amount: BigInt(80_000_00),
        toUserId: 'foreman1',
        createdAt: new Date('2025-03-10'),
      },
    ];
    const calc = new BudgetCalculator(prisma);
    const all = await calc.getMoneyFlow('p1', { userId: 'cust1', isOwner: true });
    expect(all.advances.map((a) => a.id).sort()).toEqual(['pay-jan', 'pay-mar']);
    expect(all.totals.advances).toBe(130_000_00);

    const onlyJan = await calc.getMoneyFlow(
      'p1',
      { userId: 'cust1', isOwner: true },
      { from: new Date('2025-01-01'), to: new Date('2025-01-31') },
    );
    expect(onlyJan.advances.map((a) => a.id)).toEqual(['pay-jan']);
    expect(onlyJan.totals.advances).toBe(50_000_00);

    const fromOnly = await calc.getMoneyFlow(
      'p1',
      { userId: 'cust1', isOwner: true },
      { from: new Date('2025-02-01') },
    );
    expect(fromOnly.advances.map((a) => a.id)).toEqual(['pay-mar']);
  });

  it('getMoneyFlow: возвращает pendingMaterials/rejectedMaterials/rejectedSelfpurchases и boughtBy + requestedByName', async () => {
    const { prisma, state } = mkPrisma();
    state.project = { id: 'p1', ownerId: 'cust1' };
    state.stages = [];
    state.payments = [];
    state.materialRequests = [
      {
        id: 'mr-approved',
        projectId: 'p1',
        stageId: null,
        // UI: «Согласовано». В БД: open.
        status: 'open',
        recipient: 'customer',
        title: 'Краска',
        createdById: 'cust1',
        finalizedAt: new Date('2026-04-01'),
        createdAt: new Date('2026-03-30'),
        updatedAt: new Date('2026-04-01'),
        items: [{ id: 'i1', name: 'Wall paint', totalPrice: BigInt(5_000_00) }],
      },
      {
        id: 'mr-pending',
        projectId: 'p1',
        stageId: null,
        status: 'pending_approval',
        recipient: 'foreman',
        title: 'Кафель',
        createdById: 'f1',
        finalizedAt: null,
        createdAt: new Date('2026-04-10'),
        updatedAt: new Date('2026-04-10'),
        items: [{ id: 'i2', name: 'Tile', totalPrice: BigInt(12_000_00) }],
      },
      {
        id: 'mr-rejected',
        projectId: 'p1',
        stageId: null,
        // UI: «Отклонено». В БД: cancelled.
        status: 'cancelled',
        recipient: 'foreman',
        title: 'Молотки',
        createdById: 'f1',
        finalizedAt: null,
        createdAt: new Date('2026-04-05'),
        updatedAt: new Date('2026-04-06'),
        items: [{ id: 'i3', name: 'Hammer', totalPrice: BigInt(2_000_00) }],
      },
    ];
    state.selfPurchases = [
      {
        id: 'sp-rej',
        projectId: 'p1',
        stageId: null,
        status: 'rejected',
        byRole: 'foreman',
        byUserId: 'f1',
        amount: BigInt(3_000_00),
        comment: 'без чека',
        decidedAt: new Date('2026-04-07'),
      },
    ];
    const calc = new BudgetCalculator(prisma);
    const flow = await calc.getMoneyFlow('p1', { userId: 'cust1', isOwner: true });

    expect(flow.materialPurchases.map((m) => m.requestId)).toEqual(['mr-approved']);
    expect(flow.materialPurchases[0].boughtBy).toBe('customer');
    expect(flow.materialPurchases[0].requestedByName).toBeDefined();

    expect(flow.pendingMaterials.map((p) => p.requestId)).toEqual(['mr-pending']);
    expect(flow.pendingMaterials[0].estimatedTotal).toBe(12_000_00);
    expect(flow.pendingMaterials[0].itemCount).toBe(1);

    expect(flow.rejectedMaterials.map((r) => r.requestId)).toEqual(['mr-rejected']);
    expect(flow.rejectedMaterials[0].estimatedTotal).toBe(2_000_00);

    expect(flow.rejectedSelfpurchases.map((r) => r.id)).toEqual(['sp-rej']);
    expect(flow.rejectedSelfpurchases[0].amount).toBe(3_000_00);

    // owner — wallet НЕ возвращается (только для foreman-среза).
    expect(flow.wallet).toBeUndefined();
  });

  it('getForemanMoneyFlow: возвращает wallet (advancesReceived/distributed/available)', async () => {
    const { prisma, state } = mkPrisma();
    state.project = { id: 'p1', ownerId: 'cust1' };
    state.stages = [
      {
        id: 's1',
        projectId: 'p1',
        title: 'A',
        orderIndex: 0,
        workBudget: BigInt(0),
        materialsBudget: BigInt(0),
        foremanIds: ['f1'],
      },
    ];
    state.payments = [
      {
        id: 'adv1',
        projectId: 'p1',
        kind: 'advance',
        amount: BigInt(100_000_00),
        fromUserId: 'cust1',
        toUserId: 'f1',
        createdAt: new Date('2026-04-01'),
      },
      {
        id: 'dist1',
        projectId: 'p1',
        kind: 'distribution',
        amount: BigInt(30_000_00),
        fromUserId: 'f1',
        toUserId: 'm1',
        parentPaymentId: 'adv1',
        createdAt: new Date('2026-04-05'),
      },
    ];
    state.materialRequests = [];
    state.selfPurchases = [];
    const calc = new BudgetCalculator(prisma);
    const flow = await calc.getMoneyFlow('p1', {
      userId: 'f1',
      isOwner: false,
      membershipRole: 'foreman',
      canSeeBudget: false,
    });
    expect(flow.wallet).toBeDefined();
    expect(flow.wallet!.advancesReceived).toBe(100_000_00);
    expect(flow.wallet!.distributed).toBe(30_000_00);
    expect(flow.wallet!.available).toBe(70_000_00);
  });

  it('getForemanMoneyFlow: available может быть отрицательным (выплачено больше полученного)', async () => {
    const { prisma, state } = mkPrisma();
    state.project = { id: 'p1', ownerId: 'cust1' };
    state.stages = [
      {
        id: 's1',
        projectId: 'p1',
        title: 'A',
        orderIndex: 0,
        workBudget: BigInt(0),
        materialsBudget: BigInt(0),
        foremanIds: ['f1'],
      },
    ];
    state.payments = [
      {
        id: 'adv1',
        projectId: 'p1',
        kind: 'advance',
        amount: BigInt(10_000_00),
        fromUserId: 'cust1',
        toUserId: 'f1',
        createdAt: new Date('2026-04-01'),
      },
      {
        id: 'dist1',
        projectId: 'p1',
        kind: 'distribution',
        amount: BigInt(25_000_00),
        fromUserId: 'f1',
        toUserId: 'm1',
        parentPaymentId: 'adv1',
        createdAt: new Date('2026-04-05'),
      },
    ];
    state.materialRequests = [];
    state.selfPurchases = [];
    const calc = new BudgetCalculator(prisma);
    const flow = await calc.getMoneyFlow('p1', {
      userId: 'f1',
      isOwner: false,
      membershipRole: 'foreman',
      canSeeBudget: false,
    });
    expect(flow.wallet!.available).toBe(-15_000_00);
  });
});
