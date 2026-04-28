import { SelfPurchasesService } from './selfpurchases.service';
import { FeedService } from '../feed/feed.service';
import {
  ConflictError,
  FixedClock,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';

const NOW = new Date('2026-07-20T10:00:00Z');

const mkPrisma = () => {
  const projects = new Map<string, any>();
  const stages = new Map<string, any>();
  const memberships: any[] = [];
  const selfPurchases = new Map<string, any>();
  let seq = 0;

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
              (!where.role || m.role === where.role),
          ) ?? null,
      ),
    },
    selfPurchase: {
      create: jest.fn(({ data }: any) => {
        const sp = {
          id: `sp${++seq}`,
          projectId: data.projectId,
          stageId: data.stageId ?? null,
          byUserId: data.byUserId,
          byRole: data.byRole,
          addresseeId: data.addresseeId,
          amount: data.amount,
          comment: data.comment ?? null,
          photoKeys: data.photoKeys ?? [],
          status: data.status ?? 'pending',
          decidedAt: null,
          decidedById: null,
          decisionComment: null,
          forwardedFromId: data.forwardedFromId ?? null,
          idempotencyKey: data.idempotencyKey ?? null,
          createdAt: new Date(),
          updatedAt: new Date(),
        };
        selfPurchases.set(sp.id, sp);
        return sp;
      }),
      findUnique: jest.fn(({ where }: any) => selfPurchases.get(where.id) ?? null),
      findMany: jest.fn(({ where }: any) => {
        const matches = (sp: any, w: any): boolean => {
          if (!w) return true;
          if (w.projectId && sp.projectId !== w.projectId) return false;
          if (w.status && sp.status !== w.status) return false;
          if (w.byRole && sp.byRole !== w.byRole) return false;
          if (w.byUserId && sp.byUserId !== w.byUserId) return false;
          if (w.addresseeId && sp.addresseeId !== w.addresseeId) return false;
          if (Array.isArray(w.OR)) {
            if (!w.OR.some((sub: any) => matches(sp, sub))) return false;
          }
          if (Array.isArray(w.AND)) {
            if (!w.AND.every((sub: any) => matches(sp, sub))) return false;
          }
          return true;
        };
        return [...selfPurchases.values()].filter((sp) => matches(sp, where));
      }),
      update: jest.fn(({ where, data }: any) => {
        const sp = selfPurchases.get(where.id);
        if (!sp) throw new Error('not found');
        Object.assign(sp, data);
        return sp;
      }),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };
  return {
    prisma: prisma as unknown as PrismaService,
    projects,
    stages,
    memberships,
    selfPurchases,
  };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

describe('SelfPurchasesService.create — gaps §4.3 иерархия', () => {
  it('foreman → addressee = projectOwner', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    const svc = new SelfPurchasesService(st.prisma, mkFeed(), new FixedClock(NOW));
    const sp = await svc.create({
      projectId: 'p1',
      amount: 8000_00,
      actorUserId: 'foreman1',
    });
    expect(sp.byRole).toBe('foreman');
    expect(sp.addresseeId).toBe('customer1');
    expect(sp.status).toBe('pending');
  });

  it('master → addressee = foreman стадии', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.stages.set('s1', { id: 's1', projectId: 'p1', foremanIds: ['foreman1'] });
    st.memberships.push({ projectId: 'p1', userId: 'master1', role: 'master' });
    const svc = new SelfPurchasesService(st.prisma, mkFeed(), new FixedClock(NOW));
    const sp = await svc.create({
      projectId: 'p1',
      stageId: 's1',
      amount: 3000_00,
      actorUserId: 'master1',
    });
    expect(sp.byRole).toBe('master');
    expect(sp.addresseeId).toBe('foreman1');
  });

  it('master без stageId → InvalidInputError', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'master1', role: 'master' });
    const svc = new SelfPurchasesService(st.prisma, mkFeed(), new FixedClock(NOW));
    await expect(
      svc.create({ projectId: 'p1', amount: 1000, actorUserId: 'master1' }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('master для стадии без foreman → InvalidInputError', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.stages.set('s1', { id: 's1', projectId: 'p1', foremanIds: [] });
    st.memberships.push({ projectId: 'p1', userId: 'master1', role: 'master' });
    const svc = new SelfPurchasesService(st.prisma, mkFeed(), new FixedClock(NOW));
    await expect(
      svc.create({
        projectId: 'p1',
        stageId: 's1',
        amount: 1000,
        actorUserId: 'master1',
      }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('не участник проекта → ForbiddenError', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    const svc = new SelfPurchasesService(st.prisma, mkFeed(), new FixedClock(NOW));
    await expect(
      svc.create({ projectId: 'p1', amount: 100, actorUserId: 'stranger' }),
    ).rejects.toThrow(ForbiddenError);
  });
});

describe('SelfPurchasesService.decide', () => {
  it('approved: emit selfpurchase_approved + budget_updated', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    const feed = mkFeed();
    const svc = new SelfPurchasesService(st.prisma, feed, new FixedClock(NOW));
    const sp = await svc.create({
      projectId: 'p1',
      amount: 8000_00,
      actorUserId: 'foreman1',
    });
    const approved = await svc.decide(sp.id, {
      decision: 'approved',
      actorUserId: 'customer1',
    });
    expect(approved.status).toBe('approved');
    expect(approved.decidedAt).toEqual(NOW);
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).toContain('selfpurchase_approved');
    expect(kinds).toContain('budget_updated');
  });

  it('rejected без comment → InvalidInputError', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    const svc = new SelfPurchasesService(st.prisma, mkFeed(), new FixedClock(NOW));
    const sp = await svc.create({
      projectId: 'p1',
      amount: 100,
      actorUserId: 'foreman1',
    });
    await expect(
      svc.decide(sp.id, { decision: 'rejected', actorUserId: 'customer1' }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('rejected с comment: status=rejected, budget_updated НЕ эмитится', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    const feed = mkFeed();
    const svc = new SelfPurchasesService(st.prisma, feed, new FixedClock(NOW));
    const sp = await svc.create({
      projectId: 'p1',
      amount: 100,
      actorUserId: 'foreman1',
    });
    await svc.decide(sp.id, {
      decision: 'rejected',
      comment: 'не нужно',
      actorUserId: 'customer1',
    });
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).not.toContain('budget_updated');
    expect(kinds).toContain('selfpurchase_rejected');
  });

  it('не addressee → ForbiddenError', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    const svc = new SelfPurchasesService(st.prisma, mkFeed(), new FixedClock(NOW));
    const sp = await svc.create({
      projectId: 'p1',
      amount: 100,
      actorUserId: 'foreman1',
    });
    await expect(
      svc.decide(sp.id, { decision: 'approved', actorUserId: 'stranger' }),
    ).rejects.toThrow(ForbiddenError);
  });

  it('approved master→foreman с forwardOnApprove=true: создаёт forward foreman→customer, budget_updated НЕ эмитится', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.stages.set('s1', { id: 's1', projectId: 'p1', foremanIds: ['foreman1'] });
    st.memberships.push({ projectId: 'p1', userId: 'master1', role: 'master' });
    const feed = mkFeed();
    const svc = new SelfPurchasesService(st.prisma, feed, new FixedClock(NOW));
    const original = await svc.create({
      projectId: 'p1',
      stageId: 's1',
      amount: 8500_00,
      actorUserId: 'master1',
    });
    const decided = await svc.decide(original.id, {
      decision: 'approved',
      actorUserId: 'foreman1',
      forwardOnApprove: true,
    });
    expect(decided.status).toBe('approved');
    // В Map должно быть 2 записи: оригинал master→foreman + forward foreman→customer.
    const list = [...st.selfPurchases.values()];
    expect(list).toHaveLength(2);
    const fwd = list.find((sp) => sp.forwardedFromId === original.id);
    expect(fwd).toBeDefined();
    expect(fwd?.byRole).toBe('foreman');
    expect(fwd?.addresseeId).toBe('customer1');
    expect(fwd?.byUserId).toBe('foreman1');
    expect(fwd?.status).toBe('pending');
    // mock хранит amount как BigInt — приводим перед сравнением (serialize делает то же).
    expect(Number(fwd?.amount ?? 0)).toBe(original.amount);
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    // Forward-режим эмитит ОДНО событие forwarded, НЕ approved/budget_updated.
    expect(kinds).toContain('selfpurchase_forwarded');
    expect(kinds).not.toContain('budget_updated');
    expect(kinds).not.toContain('selfpurchase_approved');
  });

  it('approved master→foreman без forwardOnApprove: budget_updated эмитится (legacy)', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.stages.set('s1', { id: 's1', projectId: 'p1', foremanIds: ['foreman1'] });
    st.memberships.push({ projectId: 'p1', userId: 'master1', role: 'master' });
    const feed = mkFeed();
    const svc = new SelfPurchasesService(st.prisma, feed, new FixedClock(NOW));
    const original = await svc.create({
      projectId: 'p1',
      stageId: 's1',
      amount: 100,
      actorUserId: 'master1',
    });
    await svc.decide(original.id, {
      decision: 'approved',
      actorUserId: 'foreman1',
    });
    const list = [...st.selfPurchases.values()];
    expect(list).toHaveLength(1);
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).toContain('selfpurchase_approved');
    expect(kinds).toContain('budget_updated');
  });

  it('forwardOnApprove игнорируется для foreman-самозакупа (только master)', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    const feed = mkFeed();
    const svc = new SelfPurchasesService(st.prisma, feed, new FixedClock(NOW));
    const sp = await svc.create({
      projectId: 'p1',
      amount: 100,
      actorUserId: 'foreman1',
    });
    await svc.decide(sp.id, {
      decision: 'approved',
      actorUserId: 'customer1',
      forwardOnApprove: true,
    });
    const list = [...st.selfPurchases.values()];
    expect(list).toHaveLength(1); // forward не создан
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).toContain('selfpurchase_approved');
    expect(kinds).toContain('budget_updated');
  });

  it('повторный decide → Conflict', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    const svc = new SelfPurchasesService(st.prisma, mkFeed(), new FixedClock(NOW));
    const sp = await svc.create({
      projectId: 'p1',
      amount: 100,
      actorUserId: 'foreman1',
    });
    await svc.decide(sp.id, { decision: 'approved', actorUserId: 'customer1' });
    await expect(
      svc.decide(sp.id, { decision: 'approved', actorUserId: 'customer1' }),
    ).rejects.toThrow(ConflictError);
  });

  it('get 404', async () => {
    const st = mkPrisma();
    const svc = new SelfPurchasesService(st.prisma, mkFeed(), new FixedClock(NOW));
    await expect(svc.get('missing')).rejects.toThrow(NotFoundError);
  });

  // ---------- P0.7.e: видимость ----------

  describe('listForProject — visibility', () => {
    const seed = () => {
      const st = mkPrisma();
      st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
      st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
      st.memberships.push({ projectId: 'p1', userId: 'master1', role: 'master' });
      st.memberships.push({ projectId: 'p1', userId: 'master2', role: 'master' });

      // master1 → foreman1 (приватный)
      const m2f = {
        id: 'sp_m2f',
        projectId: 'p1',
        stageId: null,
        byUserId: 'master1',
        byRole: 'master',
        addresseeId: 'foreman1',
        amount: 5000n,
        photoKeys: [],
        status: 'pending',
        decidedAt: null,
        decidedById: null,
        decisionComment: null,
        idempotencyKey: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      // foreman1 → customer1 (публичный)
      const f2c = {
        ...m2f,
        id: 'sp_f2c',
        byUserId: 'foreman1',
        byRole: 'foreman',
        addresseeId: 'customer1',
        amount: 30000n,
      };
      st.selfPurchases.set('sp_m2f', m2f);
      st.selfPurchases.set('sp_f2c', f2c);
      return st;
    };

    it('owner видит только foreman→customer', async () => {
      const st = seed();
      const svc = new SelfPurchasesService(st.prisma, mkFeed(), new FixedClock(NOW));
      const list = await svc.listForProject('p1', {
        userId: 'customer1',
        isOwner: true,
        membershipRole: 'customer',
      });
      expect(list.map((s) => s.id)).toEqual(['sp_f2c']);
    });

    it('foreman видит и свои (исходящие) и входящие master→foreman', async () => {
      const st = seed();
      const svc = new SelfPurchasesService(st.prisma, mkFeed(), new FixedClock(NOW));
      const list = await svc.listForProject('p1', {
        userId: 'foreman1',
        membershipRole: 'foreman',
      });
      expect(list.map((s) => s.id).sort()).toEqual(['sp_f2c', 'sp_m2f']);
    });

    it('master1 видит только своё', async () => {
      const st = seed();
      const svc = new SelfPurchasesService(st.prisma, mkFeed(), new FixedClock(NOW));
      const list = await svc.listForProject('p1', {
        userId: 'master1',
        membershipRole: 'master',
      });
      expect(list.map((s) => s.id)).toEqual(['sp_m2f']);
    });

    it('master2 не видит самозакуп master1', async () => {
      const st = seed();
      const svc = new SelfPurchasesService(st.prisma, mkFeed(), new FixedClock(NOW));
      const list = await svc.listForProject('p1', {
        userId: 'master2',
        membershipRole: 'master',
      });
      expect(list).toEqual([]);
    });

    it('owner получает 403 на самозакуп master→foreman через get()', async () => {
      const st = seed();
      const svc = new SelfPurchasesService(st.prisma, mkFeed(), new FixedClock(NOW));
      await expect(
        svc.get('sp_m2f', { userId: 'customer1', isOwner: true, membershipRole: 'customer' }),
      ).rejects.toThrow(ForbiddenError);
    });
  });
});
