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
      update: jest.fn(({ where, data }: any) => {
        const it = items.get(where.id);
        if (!it) throw new Error('material item not found');
        if (data.actualQty != null) {
          it.actualQty = new Prisma.Decimal(data.actualQty);
        }
        return it;
      }),
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
  const feed = mkFeed();
  const svc = new MaterialsService(st.prisma, feed, new FixedClock(NOW), approvalsMock as any);
  return { st, svc, approvalsMock, feed };
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

/**
 * E1a — Заявки 2.0. Флоу приёмки по ТЗ NEWFIX §5.7.
 *   open → markDelivered → delivered
 *   delivered → acceptPartial → accepted_partial
 *   accepted_partial → markDelivered (довоз) → delivered
 *   delivered → acceptFull → accepted_full
 */
describe('MaterialsService.markDelivered', () => {
  async function seedRequestWithStatus(
    status: 'pending_approval' | 'open' | 'delivered' | 'accepted_partial',
  ) {
    const ctx = baseSetup();
    // Через createRequest как customer-owner → сразу open.
    const req = await ctx.svc.createRequest({
      projectId: 'p1',
      recipient: 'foreman',
      title: 'Цемент',
      items: [{ name: 'Цемент', qty: 10, pricePerUnit: 100 }],
      actorUserId: 'c1',
    });
    if (status !== 'open') {
      // Перевести в нужный статус напрямую через мок (имитируем последующие переходы).
      ctx.st.requests.get(req.id)!.status = status;
    }
    return { ...ctx, requestId: req.id };
  }

  it('open → delivered, выставляет deliveredAt/deliveredById, эмитит material_delivered', async () => {
    const { svc, feed, requestId } = await seedRequestWithStatus('open');
    const result = await svc.markDelivered({ requestId, actorUserId: 'master1' });

    expect(result.status).toBe('delivered');
    expect(result.deliveredAt).toEqual(NOW);
    expect(result.deliveredById).toBe('master1');
    expect(feed.emit).toHaveBeenCalledWith(
      expect.objectContaining({
        kind: 'material_delivered',
        projectId: 'p1',
        actorId: 'master1',
        payload: expect.objectContaining({ requestId, title: 'Цемент' }),
      }),
    );
  });

  it('accepted_partial → delivered (довоз остатка по ТЗ §5.7 шаг 6)', async () => {
    const { svc, feed, requestId } = await seedRequestWithStatus('accepted_partial');
    const result = await svc.markDelivered({ requestId, actorUserId: 'master1' });
    expect(result.status).toBe('delivered');
    expect(feed.emit).toHaveBeenCalledWith(expect.objectContaining({ kind: 'material_delivered' }));
  });

  it('idempotent: повторный markDelivered из delivered — no-op, без второго feed-события', async () => {
    const { svc, feed, requestId } = await seedRequestWithStatus('delivered');
    (feed.emit as jest.Mock).mockClear();
    const result = await svc.markDelivered({ requestId, actorUserId: 'master1' });
    expect(result.status).toBe('delivered');
    expect(feed.emit).not.toHaveBeenCalled();
  });

  it('из pending_approval — ConflictError(MATERIAL_INVALID_STATUS)', async () => {
    const { svc, requestId } = await seedRequestWithStatus('pending_approval');
    await expect(svc.markDelivered({ requestId, actorUserId: 'master1' })).rejects.toThrow(
      ConflictError,
    );
  });

  it('несуществующая заявка → NotFoundError', async () => {
    const { svc } = baseSetup();
    await expect(
      svc.markDelivered({ requestId: 'missing', actorUserId: 'master1' }),
    ).rejects.toThrow(NotFoundError);
  });
});

describe('MaterialsService.acceptPartial', () => {
  async function seedDelivered(items: Array<{ name: string; qty: number }>) {
    const ctx = baseSetup();
    const req = await ctx.svc.createRequest({
      projectId: 'p1',
      recipient: 'foreman',
      title: 'Стяжка',
      items: items.map((i) => ({ ...i, pricePerUnit: 100 })),
      actorUserId: 'c1',
    });
    ctx.st.requests.get(req.id)!.status = 'delivered';
    const itemsList = [...ctx.st.items.values()].filter((i) => i.requestId === req.id);
    return { ...ctx, requestId: req.id, itemsList };
  }

  it('delivered → accepted_partial, сохраняет actualQty по позициям', async () => {
    const { svc, st, requestId, itemsList } = await seedDelivered([
      { name: 'Цемент', qty: 40 },
      { name: 'Песок', qty: 10 },
    ]);
    const [cement, sand] = itemsList;

    const result = await svc.acceptPartial({
      requestId,
      actorUserId: 'foreman1',
      items: [
        { itemId: cement.id, actualQty: 20 },
        { itemId: sand.id, actualQty: 10 },
      ],
    });

    expect(result.status).toBe('accepted_partial');
    expect(st.items.get(cement.id)?.actualQty?.toString()).toBe('20');
    expect(st.items.get(sand.id)?.actualQty?.toString()).toBe('10');
  });

  it('эмитит material_request_accepted_partial', async () => {
    const { svc, feed, requestId, itemsList } = await seedDelivered([{ name: 'X', qty: 5 }]);
    await svc.acceptPartial({
      requestId,
      actorUserId: 'foreman1',
      items: [{ itemId: itemsList[0].id, actualQty: 3 }],
    });
    expect(feed.emit).toHaveBeenCalledWith(
      expect.objectContaining({
        kind: 'material_request_accepted_partial',
        actorId: 'foreman1',
      }),
    );
  });

  it('actualQty > qty → InvalidInputError', async () => {
    const { svc, requestId, itemsList } = await seedDelivered([{ name: 'X', qty: 10 }]);
    await expect(
      svc.acceptPartial({
        requestId,
        actorUserId: 'foreman1',
        items: [{ itemId: itemsList[0].id, actualQty: 15 }],
      }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('itemId из другой заявки → InvalidInputError(MATERIAL_ITEM_NOT_FOUND)', async () => {
    const { svc, requestId } = await seedDelivered([{ name: 'X', qty: 5 }]);
    await expect(
      svc.acceptPartial({
        requestId,
        actorUserId: 'foreman1',
        items: [{ itemId: 'mi-foreign', actualQty: 1 }],
      }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('из open — ConflictError(требуется delivered)', async () => {
    const ctx = baseSetup();
    const req = await ctx.svc.createRequest({
      projectId: 'p1',
      recipient: 'foreman',
      title: 'X',
      items: [{ name: 'A', qty: 1, pricePerUnit: 100 }],
      actorUserId: 'c1',
    });
    // status остаётся 'open' (customer-owner создал)
    const items = [...ctx.st.items.values()].filter((i) => i.requestId === req.id);
    await expect(
      ctx.svc.acceptPartial({
        requestId: req.id,
        actorUserId: 'foreman1',
        items: [{ itemId: items[0].id, actualQty: 1 }],
      }),
    ).rejects.toThrow(ConflictError);
  });
});

describe('MaterialsService.acceptFull', () => {
  async function seedDelivered() {
    const ctx = baseSetup();
    const req = await ctx.svc.createRequest({
      projectId: 'p1',
      recipient: 'foreman',
      title: 'Финал',
      items: [
        { name: 'A', qty: 7, pricePerUnit: 100 },
        { name: 'B', qty: 3, pricePerUnit: 100 },
      ],
      actorUserId: 'c1',
    });
    ctx.st.requests.get(req.id)!.status = 'delivered';
    return { ...ctx, requestId: req.id };
  }

  it('delivered → accepted_full, выставляет actualQty=qty для всех позиций', async () => {
    const { svc, st, requestId } = await seedDelivered();
    const result = await svc.acceptFull({ requestId, actorUserId: 'foreman1' });
    expect(result.status).toBe('accepted_full');
    const items = [...st.items.values()].filter((i) => i.requestId === requestId);
    for (const it of items) {
      expect(it.actualQty?.toString()).toBe(it.qty.toString());
    }
  });

  it('эмитит material_request_accepted_full', async () => {
    const { svc, feed, requestId } = await seedDelivered();
    await svc.acceptFull({ requestId, actorUserId: 'foreman1' });
    expect(feed.emit).toHaveBeenCalledWith(
      expect.objectContaining({ kind: 'material_request_accepted_full' }),
    );
  });

  it('из open — ConflictError', async () => {
    const ctx = baseSetup();
    const req = await ctx.svc.createRequest({
      projectId: 'p1',
      recipient: 'foreman',
      title: 'X',
      items: [{ name: 'A', qty: 1, pricePerUnit: 100 }],
      actorUserId: 'c1',
    });
    await expect(
      ctx.svc.acceptFull({ requestId: req.id, actorUserId: 'foreman1' }),
    ).rejects.toThrow(ConflictError);
  });
});
