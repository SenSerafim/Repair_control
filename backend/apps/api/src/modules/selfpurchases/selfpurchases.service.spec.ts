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
          idempotencyKey: data.idempotencyKey ?? null,
          createdAt: new Date(),
          updatedAt: new Date(),
        };
        selfPurchases.set(sp.id, sp);
        return sp;
      }),
      findUnique: jest.fn(({ where }: any) => selfPurchases.get(where.id) ?? null),
      findMany: jest.fn(({ where }: any) =>
        [...selfPurchases.values()].filter((sp) => {
          if (where.projectId && sp.projectId !== where.projectId) return false;
          if (where.status && sp.status !== where.status) return false;
          return true;
        }),
      ),
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
});
