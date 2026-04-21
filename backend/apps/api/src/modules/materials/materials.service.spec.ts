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
};

const mkPrisma = () => {
  const projects = new Map<string, any>();
  const stages = new Map<string, any>();
  const requests = new Map<string, any>();
  const items = new Map<string, any>();
  const disputes: any[] = [];
  const memberships: MembershipRow[] = [];
  let rSeq = 0;
  let iSeq = 0;

  const itemsOf = (requestId: string) =>
    [...items.values()].filter((it) => it.requestId === requestId);

  const prisma: any = {
    project: {
      findUnique: jest.fn(({ where }: any) => projects.get(where.id) ?? null),
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
              (!where.stageIds?.has || (m.stageIds ?? []).includes(where.stageIds.has)),
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
          status: data.status ?? 'draft',
          finalizedAt: null,
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
              isBought: it.isBought ?? false,
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
        if (include?.disputes) out.disputes = disputes.filter((d) => d.requestId === r.id);
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
      findUnique: jest.fn(({ where, include }: any) => {
        const it = items.get(where.id);
        if (!it) return null;
        if (include?.request) {
          const r = requests.get(it.requestId);
          return {
            ...it,
            request: {
              ...r,
              items: itemsOf(r.id),
              project: projects.get(r.projectId) ?? null,
            },
          };
        }
        return it;
      }),
      findMany: jest.fn(({ where }: any) => itemsOf(where.requestId)),
      update: jest.fn(({ where, data }: any) => {
        const it = items.get(where.id);
        if (!it) throw new Error('not found');
        Object.assign(it, data);
        return it;
      }),
    },
    materialDispute: {
      create: jest.fn(({ data }: any) => {
        const d = { id: `d${disputes.length + 1}`, ...data, status: 'open', createdAt: new Date() };
        disputes.push(d);
        return d;
      }),
      updateMany: jest.fn(({ where, data }: any) => {
        const candidates = disputes.filter(
          (d) => d.requestId === where.requestId && d.status === where.status,
        );
        for (const d of candidates) Object.assign(d, data);
        return { count: candidates.length };
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
    disputes,
  };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

describe('MaterialsService.createRequest', () => {
  it('draft с items, stageId=null → «Общие материалы» (gaps §5.1)', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', status: 'active', ownerId: 'c1' });
    const feed = mkFeed();
    const svc = new MaterialsService(st.prisma, feed, new FixedClock(NOW));
    const r = await svc.createRequest({
      projectId: 'p1',
      recipient: 'foreman',
      title: 'Общий список',
      items: [{ name: 'Плитка', qty: 10, unit: 'м²' }],
      actorUserId: 'c1',
    });
    expect(r.status).toBe('draft');
    expect(r.stageId).toBeNull();
    expect(feed.emit).toHaveBeenCalledWith(
      expect.objectContaining({ kind: 'material_request_created' }),
    );
  });

  it('пустой items → InvalidInputError', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', status: 'active', ownerId: 'c1' });
    const svc = new MaterialsService(st.prisma, mkFeed(), new FixedClock(NOW));
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
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', status: 'archived', ownerId: 'c1' });
    const svc = new MaterialsService(st.prisma, mkFeed(), new FixedClock(NOW));
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

describe('MaterialsService FSM', () => {
  const setup = async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', status: 'active', ownerId: 'c1' });
    st.stages.set('s1', { id: 's1', projectId: 'p1', foremanIds: ['foreman1'] });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    st.memberships.push({
      projectId: 'p1',
      userId: 'master1',
      role: 'master',
      stageIds: ['s1'],
    });
    const svc = new MaterialsService(st.prisma, mkFeed(), new FixedClock(NOW));
    const r = await svc.createRequest({
      projectId: 'p1',
      stageId: 's1',
      recipient: 'foreman',
      title: 'Электрика',
      items: [
        { name: 'Кабель', qty: 100, unit: 'м', pricePerUnit: 50 },
        { name: 'Розетки', qty: 20, unit: 'шт', pricePerUnit: 300 },
        { name: 'Выключатели', qty: 10, unit: 'шт', pricePerUnit: 250 },
        { name: 'Коробки', qty: 15, unit: 'шт', pricePerUnit: 100 },
        { name: 'Клеммы', qty: 50, unit: 'шт', pricePerUnit: 20 },
      ],
      actorUserId: 'foreman1',
    });
    return { st, svc, requestId: r.id };
  };

  it('send: draft → open, emit material_request_sent', async () => {
    const { svc, requestId } = await setup();
    const sent = await svc.send(requestId, 'foreman1');
    expect(sent.status).toBe('open');
  });

  it('send чужой → 403', async () => {
    const { svc, requestId } = await setup();
    await expect(svc.send(requestId, 'stranger')).rejects.toThrow(ForbiddenError);
  });

  it('markItemBought: 4 из 5 → partially_bought; затем 5-й → bought', async () => {
    const { svc, requestId, st } = await setup();
    await svc.send(requestId, 'foreman1');
    const items = [...st.items.values()].filter((it) => it.requestId === requestId);
    for (let i = 0; i < 4; i++) {
      await svc.markItemBought(items[i].id, { pricePerUnit: 100 }, 'foreman1');
    }
    const partial = st.requests.get(requestId);
    expect(partial.status).toBe('partially_bought');
    await svc.markItemBought(items[4].id, { pricePerUnit: 100 }, 'foreman1');
    const all = st.requests.get(requestId);
    expect(all.status).toBe('bought');
  });

  it('finalize партии → status=bought, finalizedAt, emit budget_updated', async () => {
    const { svc, requestId, st } = await setup();
    await svc.send(requestId, 'foreman1');
    const items = [...st.items.values()].filter((it) => it.requestId === requestId);
    await svc.markItemBought(items[0].id, { pricePerUnit: 100 }, 'foreman1');
    const feed = mkFeed();
    // Создаём новый svc с пойманным feed — для утверждения
    const svc2 = new MaterialsService(st.prisma, feed, new FixedClock(NOW));
    const finalized = await svc2.finalize(requestId, 'foreman1');
    expect(finalized.status).toBe('bought');
    expect(finalized.finalizedAt).toEqual(NOW);
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).toContain('material_request_finalized');
    expect(kinds).toContain('budget_updated');
  });

  it('confirmDelivery master стадии → delivered', async () => {
    const { svc, requestId, st } = await setup();
    await svc.send(requestId, 'foreman1');
    const items = [...st.items.values()].filter((it) => it.requestId === requestId);
    await svc.markItemBought(items[0].id, { pricePerUnit: 100 }, 'foreman1');
    await svc.finalize(requestId, 'foreman1');
    const delivered = await svc.confirmDelivery(requestId, 'master1');
    expect(delivered.status).toBe('delivered');
  });

  it('confirmDelivery чужой master → 403', async () => {
    const { svc, requestId, st } = await setup();
    await svc.send(requestId, 'foreman1');
    const items = [...st.items.values()].filter((it) => it.requestId === requestId);
    await svc.markItemBought(items[0].id, { pricePerUnit: 100 }, 'foreman1');
    await svc.finalize(requestId, 'foreman1');
    await expect(svc.confirmDelivery(requestId, 'stranger')).rejects.toThrow(ForbiddenError);
  });

  it('dispute → resolve: status transitions', async () => {
    const { svc, requestId, st } = await setup();
    await svc.send(requestId, 'foreman1');
    const items = [...st.items.values()].filter((it) => it.requestId === requestId);
    await svc.markItemBought(items[0].id, { pricePerUnit: 100 }, 'foreman1');
    await svc.finalize(requestId, 'foreman1');
    await svc.confirmDelivery(requestId, 'master1');
    const disputed = await svc.dispute(requestId, 'не всё пришло', 'master1');
    expect(disputed.status).toBe('disputed');
    const resolved = await svc.resolve(requestId, {
      resolution: 'компенсация',
      actorUserId: 'c1',
    });
    expect(resolved.status).toBe('resolved');
  });

  it('get 404', async () => {
    const st = mkPrisma();
    const svc = new MaterialsService(st.prisma, mkFeed(), new FixedClock(NOW));
    await expect(svc.get('missing')).rejects.toThrow(NotFoundError);
  });
});
