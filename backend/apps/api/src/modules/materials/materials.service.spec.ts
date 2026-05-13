import { Prisma } from '@prisma/client';
import { MaterialsService } from './materials.service';
import { FeedService } from '../feed/feed.service';
import {
  ConflictError,
  FixedClock,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';

const NOW = new Date('2026-07-11T10:00:00Z');

type MembershipRow = {
  projectId: string;
  userId: string;
  role: 'customer' | 'representative' | 'foreman' | 'master';
  stageIds?: string[];
  permissions?: Record<string, boolean>;
  removedAt?: Date | null;
};

const mkPrisma = () => {
  const projects = new Map<string, any>();
  const stages = new Map<string, any>();
  const requests = new Map<string, any>();
  const items = new Map<string, any>();
  const memberships: MembershipRow[] = [];
  let rSeq = 0;
  let iSeq = 0;

  const itemsOf = (requestId: string) =>
    [...items.values()].filter((it) => it.requestId === requestId);

  const prisma: any = {
    project: {
      findUnique: jest.fn(({ where }: any) => projects.get(where.id) ?? null),
      update: jest.fn(({ where, data }: any) => {
        const p = projects.get(where.id);
        if (!p) throw new Error('project not found');
        if (data.materialsBudget?.decrement != null) {
          const cur = BigInt(p.materialsBudget ?? 0);
          p.materialsBudget = cur - BigInt(data.materialsBudget.decrement);
        }
        return p;
      }),
    },
    stage: {
      findUnique: jest.fn(({ where }: any) => stages.get(where.id) ?? null),
    },
    membership: {
      findFirst: jest.fn(
        ({ where }: any) =>
          memberships.find(
            (m) =>
              m.projectId === where.projectId &&
              m.userId === where.userId &&
              (!where.role || m.role === where.role) &&
              (where.removedAt === undefined || where.removedAt === null
                ? (m.removedAt ?? null) === null
                : true),
          ) ?? null,
      ),
    },
    materialRequest: {
      create: jest.fn(({ data, include }: any) => {
        const r = {
          id: `mr${++rSeq}`,
          projectId: data.projectId,
          stageId: data.stageId ?? null,
          createdById: data.createdById,
          recipient: data.recipient,
          title: data.title,
          comment: data.comment ?? null,
          status: data.status ?? 'pending_approval',
          finalizedAt: data.finalizedAt ?? null,
          deliveredAt: null,
          deliveredById: null,
          idempotencyKey: data.idempotencyKey ?? null,
          createdAt: new Date(),
          updatedAt: new Date(),
        };
        requests.set(r.id, r);
        if (data.items?.create) {
          for (const it of data.items.create) {
            const item = {
              id: `mi${++iSeq}`,
              requestId: r.id,
              name: it.name,
              qty: new Prisma.Decimal(it.qty),
              unit: it.unit ?? null,
              note: it.note ?? null,
              pricePerUnit: it.pricePerUnit ?? null,
              totalPrice: it.totalPrice ?? null,
              isBought: false,
              boughtAt: null,
              createdAt: new Date(),
              updatedAt: new Date(),
            };
            items.set(item.id, item);
          }
        }
        if (include?.items) return { ...r, items: itemsOf(r.id) };
        return r;
      }),
      findUnique: jest.fn(({ where, include }: any) => {
        const r = requests.get(where.id);
        if (!r) return null;
        const out: any = { ...r };
        if (include?.items) out.items = itemsOf(r.id);
        if (include?.stage) out.stage = r.stageId ? (stages.get(r.stageId) ?? null) : null;
        if (include?.project) out.project = projects.get(r.projectId) ?? null;
        return out;
      }),
      findMany: jest.fn(({ where }: any) =>
        [...requests.values()].filter((r) => {
          if (where.projectId && r.projectId !== where.projectId) return false;
          if (where.status && r.status !== where.status) return false;
          return true;
        }),
      ),
      update: jest.fn(({ where, data }: any) => {
        const r = requests.get(where.id);
        if (!r) throw new Error('not found');
        Object.assign(r, data);
        return r;
      }),
    },
    materialItem: {
      findUnique: jest.fn(({ where }: any) => items.get(where.id) ?? null),
      findMany: jest.fn(({ where }: any) => itemsOf(where.requestId)),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };
  return {
    prisma: prisma as unknown as PrismaService,
    projects,
    stages,
    requests,
    items,
    memberships,
  };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

/**
 * Тестовый сетап:
 *   project p1, owner=c1 (customer), materialsBudget=1_000_000 копеек
 *   stage s1, foreman=foreman1
 *   master1 — мастер, назначен на s1
 *   stranger — не в проекте
 */
const baseSetup = () => {
  const st = mkPrisma();
  st.projects.set('p1', {
    id: 'p1',
    status: 'active',
    ownerId: 'c1',
    materialsBudget: BigInt(1_000_000),
  });
  st.stages.set('s1', { id: 's1', projectId: 'p1', foremanIds: ['foreman1'] });
  st.memberships.push({ projectId: 'p1', userId: 'c1', role: 'customer' });
  st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
  st.memberships.push({
    projectId: 'p1',
    userId: 'master1',
    role: 'master',
    stageIds: ['s1'],
  });
  const approvalsMock = {
    request: jest.fn().mockResolvedValue({ id: 'ap-mirror' }),
  };
  const svc = new MaterialsService(st.prisma, mkFeed(), new FixedClock(NOW), approvalsMock as any);
  return { st, svc, approvalsMock };
};

describe('MaterialsService.createRequest', () => {
  it('foreman создаёт → status=pending_approval + Approval(material_purchase)', async () => {
    const { st, svc, approvalsMock } = baseSetup();
    const r = await svc.createRequest({
      projectId: 'p1',
      stageId: 's1',
      recipient: 'foreman',
      title: 'Электрика',
      items: [{ name: 'Кабель', qty: 10, unit: 'м', pricePerUnit: 50 }],
      actorUserId: 'foreman1',
    });
    expect(r.status).toBe('pending_approval');
    expect(approvalsMock.request).toHaveBeenCalledTimes(1);
    const arg = approvalsMock.request.mock.calls[0][0];
    expect(arg.scope).toBe('material_purchase');
    expect(arg.addresseeId).toBe('c1');
    expect((arg.payload as any).materialRequestId).toBe(r.id);
    expect((arg.payload as any).amount).toBe(500);
    // Бюджет не тронут до согласования
    expect(st.projects.get('p1').materialsBudget).toBe(BigInt(1_000_000));
  });

  it('customer-owner создаёт → сразу status=open, project.materialsBudget не мутируется (calc сам учитывает spent)', async () => {
    const { st, svc, approvalsMock } = baseSetup();
    const r = await svc.createRequest({
      projectId: 'p1',
      recipient: 'foreman',
      title: 'Общий список',
      items: [
        { name: 'Плитка', qty: 10, unit: 'м²', pricePerUnit: 1000 },
        { name: 'Клей', qty: 5, unit: 'кг', pricePerUnit: 200 },
      ],
      actorUserId: 'c1',
    });
    expect(r.status).toBe('open');
    expect(r.finalizedAt).toEqual(NOW);
    expect(approvalsMock.request).not.toHaveBeenCalled();
    // 2026-05-13: project.materialsBudget — это «план», не мутируется.
    // BudgetCalculator считает spent отдельно по materialRequest.items.
    expect(st.projects.get('p1').materialsBudget).toBe(BigInt(1_000_000));
  });

  it('representative.canApprove создаёт → сразу open, бюджет проекта не мутируется', async () => {
    const { st, svc, approvalsMock } = baseSetup();
    st.memberships.push({
      projectId: 'p1',
      userId: 'rep1',
      role: 'representative',
      permissions: { canApprove: true },
    });
    const r = await svc.createRequest({
      projectId: 'p1',
      recipient: 'foreman',
      title: 'rep request',
      items: [{ name: 'a', qty: 1, pricePerUnit: 333 }],
      actorUserId: 'rep1',
    });
    expect(r.status).toBe('open');
    expect(approvalsMock.request).not.toHaveBeenCalled();
    expect(st.projects.get('p1').materialsBudget).toBe(BigInt(1_000_000));
  });

  it('master создаёт → pending_approval + Approval, бюджет не тронут', async () => {
    const { svc, approvalsMock, st } = baseSetup();
    const r = await svc.createRequest({
      projectId: 'p1',
      stageId: 's1',
      recipient: 'foreman',
      title: 'm',
      items: [{ name: 'a', qty: 1, pricePerUnit: 100 }],
      actorUserId: 'master1',
    });
    expect(r.status).toBe('pending_approval');
    expect(approvalsMock.request).toHaveBeenCalled();
    expect(st.projects.get('p1').materialsBudget).toBe(BigInt(1_000_000));
  });

  it('items без цены — заявка создаётся, бюджет не тронут (auto-approve без декремента)', async () => {
    const { svc, st } = baseSetup();
    const r = await svc.createRequest({
      projectId: 'p1',
      recipient: 'foreman',
      title: 'неоценённая',
      items: [{ name: 'мелочёвка', qty: 1 }],
      actorUserId: 'c1',
    });
    expect(r.status).toBe('open');
    expect(st.projects.get('p1').materialsBudget).toBe(BigInt(1_000_000));
  });

  it('не участник → 403', async () => {
    const { svc } = baseSetup();
    await expect(
      svc.createRequest({
        projectId: 'p1',
        recipient: 'foreman',
        title: 'x',
        items: [{ name: 'a', qty: 1 }],
        actorUserId: 'stranger',
      }),
    ).rejects.toThrow(ForbiddenError);
  });

  it('пустой items → InvalidInputError', async () => {
    const { svc } = baseSetup();
    await expect(
      svc.createRequest({
        projectId: 'p1',
        recipient: 'foreman',
        title: 'X',
        items: [],
        actorUserId: 'c1',
      }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('archived project → Conflict', async () => {
    const { st, svc } = baseSetup();
    st.projects.set('p1', { id: 'p1', status: 'archived', ownerId: 'c1' });
    await expect(
      svc.createRequest({
        projectId: 'p1',
        recipient: 'foreman',
        title: 'X',
        items: [{ name: 'A', qty: 1 }],
        actorUserId: 'c1',
      }),
    ).rejects.toThrow(ConflictError);
  });
});

describe('MaterialsService.resolvePurchaseApproval', () => {
  const prepare = async () => {
    const { st, svc } = baseSetup();
    const r = await svc.createRequest({
      projectId: 'p1',
      stageId: 's1',
      recipient: 'foreman',
      title: 'x',
      items: [
        { name: 'a', qty: 1, pricePerUnit: 100 },
        { name: 'b', qty: 2, pricePerUnit: 200 },
      ],
      actorUserId: 'foreman1',
    });
    return { st, svc, requestId: r.id };
  };

  it('approve → status=open + finalizedAt, project.materialsBudget не мутируется (источник истины — calculator)', async () => {
    const { svc, requestId, st } = await prepare();
    await svc.resolvePurchaseApproval(requestId, {
      decision: 'approved',
      actorUserId: 'c1',
      actorSystemRole: 'customer',
    });
    const r = st.requests.get(requestId);
    expect(r.status).toBe('open');
    expect(r.finalizedAt).toEqual(NOW);
    // 2026-05-13: ранее тут вычитали 500 из materialsBudget — это давало
    // ДВОЙНОЕ списание, потому что BudgetCalculator считает spent через
    // sum(approved-materialRequest.items.totalPrice). Теперь project.
    // materialsBudget = «план» и стабилен.
    expect(st.projects.get('p1').materialsBudget).toBe(BigInt(1_000_000));
  });

  it('reject → status=cancelled, бюджет не трогается', async () => {
    const { svc, requestId, st } = await prepare();
    await svc.resolvePurchaseApproval(requestId, {
      decision: 'rejected',
      comment: 'нет',
      actorUserId: 'c1',
      actorSystemRole: 'customer',
    });
    expect(st.requests.get(requestId).status).toBe('cancelled');
    expect(st.projects.get('p1').materialsBudget).toBe(BigInt(1_000_000));
  });

  it('повторное resolve уже cancelled → ConflictError', async () => {
    const { svc, requestId } = await prepare();
    await svc.resolvePurchaseApproval(requestId, {
      decision: 'rejected',
      comment: 'нет',
      actorUserId: 'c1',
      actorSystemRole: 'customer',
    });
    await expect(
      svc.resolvePurchaseApproval(requestId, {
        decision: 'approved',
        actorUserId: 'c1',
        actorSystemRole: 'customer',
      }),
    ).rejects.toThrow(ConflictError);
  });

  it('повторное approve уже open → ConflictError', async () => {
    const { svc, requestId } = await prepare();
    await svc.resolvePurchaseApproval(requestId, {
      decision: 'approved',
      actorUserId: 'c1',
      actorSystemRole: 'customer',
    });
    await expect(
      svc.resolvePurchaseApproval(requestId, {
        decision: 'approved',
        actorUserId: 'c1',
        actorSystemRole: 'customer',
      }),
    ).rejects.toThrow(ConflictError);
  });

  it('resolve несуществующей заявки → NotFoundError', async () => {
    const { svc } = baseSetup();
    await expect(
      svc.resolvePurchaseApproval('missing', {
        decision: 'approved',
        actorUserId: 'c1',
        actorSystemRole: 'customer',
      }),
    ).rejects.toThrow(NotFoundError);
  });
});

describe('MaterialsService.get / listForProject', () => {
  it('get: 404 при отсутствии', async () => {
    const { svc } = baseSetup();
    await expect(svc.get('missing')).rejects.toThrow(NotFoundError);
  });

  it('listForProject возвращает заявки всех статусов проекта', async () => {
    const { svc } = baseSetup();
    await svc.createRequest({
      projectId: 'p1',
      recipient: 'foreman',
      title: 'a',
      items: [{ name: 'x', qty: 1, pricePerUnit: 10 }],
      actorUserId: 'c1',
    });
    await svc.createRequest({
      projectId: 'p1',
      recipient: 'foreman',
      title: 'b',
      items: [{ name: 'y', qty: 1, pricePerUnit: 20 }],
      actorUserId: 'foreman1',
    });
    const all = await svc.listForProject('p1');
    expect(all).toHaveLength(2);
    const statuses = all.map((r) => r.status).sort();
    expect(statuses).toEqual(['open', 'pending_approval']);
  });
});
