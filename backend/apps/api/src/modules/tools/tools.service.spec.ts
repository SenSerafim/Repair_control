import { ToolsService } from './tools.service';
import { FeedService } from '../feed/feed.service';
import {
  ConflictError,
  FixedClock,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';

const NOW = new Date('2026-07-21T10:00:00Z');

const mkPrisma = () => {
  const users = new Map<string, any>();
  const tools = new Map<string, any>();
  const issuances = new Map<string, any>();
  const memberships: any[] = [];
  let tSeq = 0;
  let iSeq = 0;

  const prisma: any = {
    user: {
      findUnique: jest.fn(({ where, include }: any) => {
        const u = users.get(where.id);
        if (!u) return null;
        if (include?.roles) return { ...u, roles: u.roles ?? [] };
        return u;
      }),
    },
    toolItem: {
      create: jest.fn(({ data }: any) => {
        const t = {
          id: `tl${++tSeq}`,
          ownerId: data.ownerId,
          name: data.name,
          totalQty: data.totalQty,
          issuedQty: 0,
          unit: data.unit ?? 'шт',
          photoKey: data.photoKey ?? null,
          createdAt: new Date(),
          updatedAt: new Date(),
        };
        tools.set(t.id, t);
        return t;
      }),
      findUnique: jest.fn(({ where }: any) => tools.get(where.id) ?? null),
      findMany: jest.fn(({ where }: any) =>
        [...tools.values()].filter((t) => !where.ownerId || t.ownerId === where.ownerId),
      ),
      update: jest.fn(({ where, data }: any) => {
        const t = tools.get(where.id);
        if (!t) throw new Error('not found');
        for (const [k, v] of Object.entries(data)) {
          if (typeof v === 'object' && v && 'increment' in (v as any)) {
            (t as any)[k] += (v as any).increment;
          } else if (typeof v === 'object' && v && 'decrement' in (v as any)) {
            (t as any)[k] -= (v as any).decrement;
          } else {
            (t as any)[k] = v;
          }
        }
        return t;
      }),
    },
    toolIssuance: {
      create: jest.fn(({ data }: any) => {
        const iss = {
          id: `iss${++iSeq}`,
          toolItemId: data.toolItemId,
          projectId: data.projectId ?? null,
          stageId: data.stageId ?? null,
          toUserId: data.toUserId,
          issuedById: data.issuedById,
          qty: data.qty,
          returnedQty: null,
          status: data.status ?? 'issued',
          issuedAt: new Date(),
          confirmedAt: null,
          returnedAt: null,
          returnConfirmedAt: null,
          createdAt: new Date(),
          updatedAt: new Date(),
        };
        issuances.set(iss.id, iss);
        return iss;
      }),
      findUnique: jest.fn(({ where, include }: any) => {
        const iss = issuances.get(where.id);
        if (!iss) return null;
        if (include?.toolItem) return { ...iss, toolItem: tools.get(iss.toolItemId) };
        return iss;
      }),
      update: jest.fn(({ where, data }: any) => {
        const iss = issuances.get(where.id);
        if (!iss) throw new Error('not found');
        Object.assign(iss, data);
        return iss;
      }),
      findMany: jest.fn(({ where }: any) =>
        [...issuances.values()].filter((iss) => {
          if (where.projectId && iss.projectId !== where.projectId) return false;
          if (where.toUserId && iss.toUserId !== where.toUserId) return false;
          return true;
        }),
      ),
    },
    membership: {
      findFirst: jest.fn(
        ({ where }: any) =>
          memberships.find(
            (m) =>
              m.projectId === where.projectId &&
              m.userId === where.userId &&
              (!where.role || m.role === where.role),
          ) ?? null,
      ),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };
  return { prisma: prisma as unknown as PrismaService, users, tools, issuances, memberships };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

describe('ToolsService.createToolItem', () => {
  it('создаёт ToolItem на профиле foreman (gaps §5.2)', async () => {
    const st = mkPrisma();
    st.users.set('foreman1', {
      id: 'foreman1',
      roles: [{ role: 'contractor', isActive: true }],
    });
    const svc = new ToolsService(st.prisma, mkFeed(), new FixedClock(NOW));
    const t = await svc.createToolItem({
      ownerId: 'foreman1',
      name: 'Перфоратор',
      totalQty: 5,
    });
    expect(t.ownerId).toBe('foreman1');
    expect(t.issuedQty).toBe(0);
  });

  it('не contractor → ForbiddenError', async () => {
    const st = mkPrisma();
    st.users.set('customer1', {
      id: 'customer1',
      roles: [{ role: 'customer', isActive: true }],
    });
    const svc = new ToolsService(st.prisma, mkFeed(), new FixedClock(NOW));
    await expect(
      svc.createToolItem({ ownerId: 'customer1', name: 'X', totalQty: 1 }),
    ).rejects.toThrow(ForbiddenError);
  });
});

describe('ToolsService.issue', () => {
  const setup = async () => {
    const st = mkPrisma();
    st.users.set('foreman1', {
      id: 'foreman1',
      roles: [{ role: 'contractor', isActive: true }],
    });
    st.memberships.push({ projectId: 'p1', userId: 'master1', role: 'master' });
    const svc = new ToolsService(st.prisma, mkFeed(), new FixedClock(NOW));
    const t = await svc.createToolItem({
      ownerId: 'foreman1',
      name: 'Перфоратор',
      totalQty: 10,
    });
    return { st, svc, toolId: t.id };
  };

  it('issue qty=10 из 10 → ok, issuedQty=10', async () => {
    const { st, svc, toolId } = await setup();
    const iss = await svc.issue({
      toolItemId: toolId,
      projectId: 'p1',
      toUserId: 'master1',
      qty: 10,
      actorUserId: 'foreman1',
    });
    expect(iss.status).toBe('issued');
    expect(iss.qty).toBe(10);
    expect(st.tools.get(toolId).issuedQty).toBe(10);
  });

  it('issue qty > available → ConflictError', async () => {
    const { svc, toolId } = await setup();
    await svc.issue({
      toolItemId: toolId,
      projectId: 'p1',
      toUserId: 'master1',
      qty: 8,
      actorUserId: 'foreman1',
    });
    await expect(
      svc.issue({
        toolItemId: toolId,
        projectId: 'p1',
        toUserId: 'master1',
        qty: 5,
        actorUserId: 'foreman1',
      }),
    ).rejects.toThrow(ConflictError);
  });

  it('не owner → ForbiddenError', async () => {
    const { svc, toolId } = await setup();
    await expect(
      svc.issue({
        toolItemId: toolId,
        projectId: 'p1',
        toUserId: 'master1',
        qty: 1,
        actorUserId: 'stranger',
      }),
    ).rejects.toThrow(ForbiddenError);
  });

  it('toUserId не master проекта → InvalidInputError', async () => {
    const { svc, toolId } = await setup();
    await expect(
      svc.issue({
        toolItemId: toolId,
        projectId: 'p1',
        toUserId: 'notmaster',
        qty: 1,
        actorUserId: 'foreman1',
      }),
    ).rejects.toThrow(InvalidInputError);
  });
});

describe('ToolsService FSM: issue → confirm → requestReturn → confirmReturn', () => {
  const setup = async () => {
    const st = mkPrisma();
    st.users.set('foreman1', {
      id: 'foreman1',
      roles: [{ role: 'contractor', isActive: true }],
    });
    st.memberships.push({ projectId: 'p1', userId: 'master1', role: 'master' });
    const svc = new ToolsService(st.prisma, mkFeed(), new FixedClock(NOW));
    const t = await svc.createToolItem({
      ownerId: 'foreman1',
      name: 'Перфоратор',
      totalQty: 10,
    });
    const iss = await svc.issue({
      toolItemId: t.id,
      projectId: 'p1',
      toUserId: 'master1',
      qty: 10,
      actorUserId: 'foreman1',
    });
    return { st, svc, toolId: t.id, issuanceId: iss.id };
  };

  it('master подтверждает приёмку → status=confirmed', async () => {
    const { svc, issuanceId } = await setup();
    const u = await svc.confirmReceipt(issuanceId, 'master1');
    expect(u.status).toBe('confirmed');
    expect(u.confirmedAt).toEqual(NOW);
  });

  it('не мастер пытается подтвердить → ForbiddenError', async () => {
    const { svc, issuanceId } = await setup();
    await expect(svc.confirmReceipt(issuanceId, 'foreman1')).rejects.toThrow(ForbiddenError);
  });

  it('полный цикл возврата: 10→8→бригадир подтвердил→issuedQty=2', async () => {
    const { st, svc, toolId, issuanceId } = await setup();
    await svc.confirmReceipt(issuanceId, 'master1');
    const retReq = await svc.requestReturn(issuanceId, 8, 'master1');
    expect(retReq.status).toBe('return_requested');
    expect(retReq.returnedQty).toBe(8);
    // issuedQty пока не изменился
    expect(st.tools.get(toolId).issuedQty).toBe(10);
    // Бригадир подтверждает возврат
    const done = await svc.confirmReturn(issuanceId, 'foreman1');
    expect(done.status).toBe('returned');
    expect(st.tools.get(toolId).issuedQty).toBe(2);
  });

  it('requestReturn qty > issued → InvalidInputError', async () => {
    const { svc, issuanceId } = await setup();
    await svc.confirmReceipt(issuanceId, 'master1');
    await expect(svc.requestReturn(issuanceId, 20, 'master1')).rejects.toThrow(InvalidInputError);
  });

  it('requestReturn в статусе issued (без confirm) → Conflict', async () => {
    const { svc, issuanceId } = await setup();
    await expect(svc.requestReturn(issuanceId, 5, 'master1')).rejects.toThrow(ConflictError);
  });

  it('confirmReturn не owner → Forbidden', async () => {
    const { svc, issuanceId } = await setup();
    await svc.confirmReceipt(issuanceId, 'master1');
    await svc.requestReturn(issuanceId, 5, 'master1');
    await expect(svc.confirmReturn(issuanceId, 'stranger')).rejects.toThrow(ForbiddenError);
  });
});

describe('ToolsService.listIssuancesForProject — customer не видит (ТЗ §1.4)', () => {
  it('customer получает 403', async () => {
    const st = mkPrisma();
    const svc = new ToolsService(st.prisma, mkFeed(), new FixedClock(NOW));
    await expect(svc.listIssuancesForProject('p1', 'customer1', 'customer')).rejects.toThrow(
      ForbiddenError,
    );
  });

  it('master видит только свои выдачи (фильтрация по toUserId)', async () => {
    const st = mkPrisma();
    st.users.set('foreman1', {
      id: 'foreman1',
      roles: [{ role: 'contractor', isActive: true }],
    });
    st.memberships.push({ projectId: 'p1', userId: 'master1', role: 'master' });
    st.memberships.push({ projectId: 'p1', userId: 'master2', role: 'master' });
    const svc = new ToolsService(st.prisma, mkFeed(), new FixedClock(NOW));
    const t = await svc.createToolItem({
      ownerId: 'foreman1',
      name: 'X',
      totalQty: 20,
    });
    await svc.issue({
      toolItemId: t.id,
      projectId: 'p1',
      toUserId: 'master1',
      qty: 5,
      actorUserId: 'foreman1',
    });
    await svc.issue({
      toolItemId: t.id,
      projectId: 'p1',
      toUserId: 'master2',
      qty: 5,
      actorUserId: 'foreman1',
    });
    const visible = await svc.listIssuancesForProject('p1', 'master1', 'master');
    expect(visible).toHaveLength(1);
  });
});

describe('ToolsService.updateToolItem sanity', () => {
  it('totalQty < issuedQty → InvalidInputError', async () => {
    const st = mkPrisma();
    st.users.set('foreman1', {
      id: 'foreman1',
      roles: [{ role: 'contractor', isActive: true }],
    });
    st.memberships.push({ projectId: 'p1', userId: 'master1', role: 'master' });
    const svc = new ToolsService(st.prisma, mkFeed(), new FixedClock(NOW));
    const t = await svc.createToolItem({
      ownerId: 'foreman1',
      name: 'X',
      totalQty: 10,
    });
    await svc.issue({
      toolItemId: t.id,
      projectId: 'p1',
      toUserId: 'master1',
      qty: 8,
      actorUserId: 'foreman1',
    });
    await expect(svc.updateToolItem(t.id, { totalQty: 5 }, 'foreman1')).rejects.toThrow(
      InvalidInputError,
    );
  });

  it('get not found → 404', async () => {
    const st = mkPrisma();
    const svc = new ToolsService(st.prisma, mkFeed(), new FixedClock(NOW));
    await expect(svc.getTool('missing', 'u')).rejects.toThrow(NotFoundError);
  });
});
