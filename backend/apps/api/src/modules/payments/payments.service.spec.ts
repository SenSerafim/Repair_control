import { PaymentsService } from './payments.service';
import { FeedService } from '../feed/feed.service';
import {
  ConflictError,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';

type ProjectRow = { id: string; ownerId: string; status: 'active' | 'archived' };
type MembershipRow = {
  projectId: string;
  userId: string;
  role: 'customer' | 'representative' | 'foreman' | 'master';
  removedAt: Date | null;
};
type PaymentRow = {
  id: string;
  projectId: string;
  stageId: string | null;
  parentPaymentId: string | null;
  kind: 'advance' | 'distribution' | 'correction';
  fromUserId: string;
  toUserId: string;
  amount: bigint;
  comment: string | null;
  photoKey: string | null;
  idempotencyKey: string | null;
  createdAt: Date;
  updatedAt: Date;
};

const mkPrisma = () => {
  const projects = new Map<string, ProjectRow>();
  const memberships: MembershipRow[] = [];
  const payments = new Map<string, PaymentRow>();
  let pSeq = 0;

  const prisma: any = {
    project: {
      findUnique: jest.fn(({ where }: any) => projects.get(where.id) ?? null),
    },
    membership: {
      findFirst: jest.fn(({ where }: any) => {
        const roleMatches = (m: MembershipRow): boolean => {
          if (!where.role) return true;
          if (typeof where.role === 'string') return m.role === where.role;
          if (where.role.in) return (where.role.in as string[]).includes(m.role);
          return false;
        };
        return (
          memberships.find(
            (m) =>
              m.projectId === where.projectId &&
              m.userId === where.userId &&
              roleMatches(m) &&
              (where.removedAt === null ? m.removedAt === null : true),
          ) ?? null
        );
      }),
    },
    payment: {
      findUnique: jest.fn(({ where, include }: any) => {
        const p = payments.get(where.id);
        if (!p) return null;
        if (include?.children) {
          const children = [...payments.values()].filter((c) => c.parentPaymentId === p.id);
          return { ...p, children };
        }
        if (include?.project) {
          const proj = projects.get(p.projectId);
          return { ...p, project: proj ? { ownerId: proj.ownerId } : null };
        }
        return p;
      }),
      findMany: jest.fn(({ where }: any) => {
        const matches = (p: PaymentRow, w: any): boolean => {
          if (!w) return true;
          if (w.projectId && p.projectId !== w.projectId) return false;
          if (w.kind && p.kind !== w.kind) return false;
          if (w.parentPaymentId && p.parentPaymentId !== w.parentPaymentId) return false;
          if (w.fromUserId && p.fromUserId !== w.fromUserId) return false;
          if (w.toUserId && p.toUserId !== w.toUserId) return false;
          if (Array.isArray(w.OR)) {
            if (!w.OR.some((sub: any) => matches(p, sub))) return false;
          }
          if (Array.isArray(w.AND)) {
            if (!w.AND.every((sub: any) => matches(p, sub))) return false;
          }
          return true;
        };
        return [...payments.values()].filter((p) => matches(p, where));
      }),
      create: jest.fn(({ data }: any) => {
        const now = new Date();
        const row: PaymentRow = {
          id: `pay${++pSeq}`,
          projectId: data.projectId,
          stageId: data.stageId ?? null,
          parentPaymentId: data.parentPaymentId ?? null,
          kind: data.kind,
          fromUserId: data.fromUserId,
          toUserId: data.toUserId,
          amount: data.amount,
          comment: data.comment ?? null,
          photoKey: data.photoKey ?? null,
          idempotencyKey: data.idempotencyKey ?? null,
          createdAt: now,
          updatedAt: now,
        };
        payments.set(row.id, row);
        return row;
      }),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };
  return { prisma: prisma as unknown as PrismaService, projects, memberships, payments };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

const makeService = (st: ReturnType<typeof mkPrisma>, feed = mkFeed()) =>
  new PaymentsService(st.prisma, feed);

describe('PaymentsService.createAdvance', () => {
  it('создаёт advance customer→foreman и эмитит payment_created + budget_updated', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({
      projectId: 'p1',
      userId: 'foreman1',
      role: 'foreman',
      removedAt: null,
    });
    const feed = mkFeed();
    const svc = makeService(st, feed);
    const p = await svc.createAdvance({
      projectId: 'p1',
      toUserId: 'foreman1',
      amount: 500_000_00,
      actorUserId: 'customer1',
      idempotencyKey: 'k-1',
    });
    expect(p.kind).toBe('advance');
    expect(Number(p.amount)).toBe(500_000_00);
    expect(feed.emit).toHaveBeenCalledWith(expect.objectContaining({ kind: 'payment_created' }));
    expect(feed.emit).toHaveBeenCalledWith(expect.objectContaining({ kind: 'budget_updated' }));
  });

  it('customer→master напрямую разрешён', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({
      projectId: 'p1',
      userId: 'master1',
      role: 'master',
      removedAt: null,
    });
    const svc = makeService(st);
    const p = await svc.createAdvance({
      projectId: 'p1',
      toUserId: 'master1',
      amount: 50_000_00,
      actorUserId: 'customer1',
    });
    expect(p.toUserId).toBe('master1');
    expect(p.kind).toBe('advance');
  });

  it('amount=0 → InvalidInputError', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'c', status: 'active' });
    const svc = makeService(st);
    await expect(
      svc.createAdvance({ projectId: 'p1', toUserId: 'x', amount: 0, actorUserId: 'c' }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('self-payment запрещён', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'c1', status: 'active' });
    const svc = makeService(st);
    await expect(
      svc.createAdvance({
        projectId: 'p1',
        toUserId: 'c1',
        amount: 1_000_00,
        actorUserId: 'c1',
      }),
    ).rejects.toThrow(ForbiddenError);
  });

  it('archived проект → ConflictError', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'c1', status: 'archived' });
    st.memberships.push({
      projectId: 'p1',
      userId: 'foreman1',
      role: 'foreman',
      removedAt: null,
    });
    const svc = makeService(st);
    await expect(
      svc.createAdvance({
        projectId: 'p1',
        toUserId: 'foreman1',
        amount: 1_000_00,
        actorUserId: 'c1',
      }),
    ).rejects.toThrow(ConflictError);
  });

  it('получатель не foreman/master → InvalidInputError', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'c1', status: 'active' });
    const svc = makeService(st);
    await expect(
      svc.createAdvance({
        projectId: 'p1',
        toUserId: 'someone',
        amount: 1_000_00,
        actorUserId: 'c1',
      }),
    ).rejects.toThrow(InvalidInputError);
  });
});

describe('PaymentsService.createDistribution', () => {
  const seedAdvance = (st: ReturnType<typeof mkPrisma>): PaymentRow => {
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({
      projectId: 'p1',
      userId: 'foreman1',
      role: 'foreman',
      removedAt: null,
    });
    st.memberships.push({
      projectId: 'p1',
      userId: 'master1',
      role: 'master',
      removedAt: null,
    });
    const adv: PaymentRow = {
      id: 'advP',
      projectId: 'p1',
      stageId: null,
      parentPaymentId: null,
      kind: 'advance',
      fromUserId: 'customer1',
      toUserId: 'foreman1',
      amount: BigInt(100_000_00),
      comment: null,
      photoKey: null,
      idempotencyKey: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    st.payments.set(adv.id, adv);
    return adv;
  };

  it('foreman распределяет мастеру — distribution создаётся, emits payment_distributed', async () => {
    const st = mkPrisma();
    seedAdvance(st);
    const feed = mkFeed();
    const svc = makeService(st, feed);
    const p = await svc.createDistribution({
      parentPaymentId: 'advP',
      toUserId: 'master1',
      amount: 30_000_00,
      actorUserId: 'foreman1',
    });
    expect(p.kind).toBe('distribution');
    expect(p.parentPaymentId).toBe('advP');
    expect(p.toUserId).toBe('master1');
    expect(feed.emit).toHaveBeenCalledWith(
      expect.objectContaining({ kind: 'payment_distributed' }),
    );
  });

  it('не foreman parent.toUserId → ForbiddenError', async () => {
    const st = mkPrisma();
    seedAdvance(st);
    const svc = makeService(st);
    await expect(
      svc.createDistribution({
        parentPaymentId: 'advP',
        toUserId: 'master1',
        amount: 1_000_00,
        actorUserId: 'someone_else',
      }),
    ).rejects.toThrow(ForbiddenError);
  });

  it('parent не advance → ConflictError', async () => {
    const st = mkPrisma();
    seedAdvance(st);
    st.payments.set('dist1', {
      ...st.payments.get('advP')!,
      id: 'dist1',
      kind: 'distribution',
      parentPaymentId: 'advP',
    });
    const svc = makeService(st);
    await expect(
      svc.createDistribution({
        parentPaymentId: 'dist1',
        toUserId: 'master1',
        amount: 1_000_00,
        actorUserId: 'foreman1',
      }),
    ).rejects.toThrow(ConflictError);
  });

  it('получатель не master → InvalidInputError', async () => {
    const st = mkPrisma();
    seedAdvance(st);
    const svc = makeService(st);
    await expect(
      svc.createDistribution({
        parentPaymentId: 'advP',
        toUserId: 'outsider',
        amount: 1_000_00,
        actorUserId: 'foreman1',
      }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('parent не найден → NotFoundError', async () => {
    const st = mkPrisma();
    const svc = makeService(st);
    await expect(
      svc.createDistribution({
        parentPaymentId: 'nope',
        toUserId: 'm',
        amount: 1_000_00,
        actorUserId: 'f',
      }),
    ).rejects.toThrow(NotFoundError);
  });

  it('distribution может превышать parent.amount — записывается без блокировки', async () => {
    const st = mkPrisma();
    seedAdvance(st);
    const svc = makeService(st);
    const p = await svc.createDistribution({
      parentPaymentId: 'advP',
      toUserId: 'master1',
      amount: 200_000_00,
      actorUserId: 'foreman1',
    });
    expect(Number(p.amount)).toBe(200_000_00);
  });

  describe('из кассы бригадира (без parentPaymentId)', () => {
    it('foreman→master без parent — создаётся distribution с parentPaymentId=null', async () => {
      const st = mkPrisma();
      seedAdvance(st);
      const feed = mkFeed();
      const svc = makeService(st, feed);
      const p = await svc.createDistribution({
        projectId: 'p1',
        toUserId: 'master1',
        amount: 30_000_00,
        actorUserId: 'foreman1',
      });
      expect(p.kind).toBe('distribution');
      expect(p.parentPaymentId).toBeNull();
      expect(p.toUserId).toBe('master1');
      expect(p.fromUserId).toBe('foreman1');
      expect(Number(p.amount)).toBe(30_000_00);
      expect(feed.emit).toHaveBeenCalledWith(
        expect.objectContaining({ kind: 'payment_distributed' }),
      );
    });

    it('actor не foreman проекта → ForbiddenError', async () => {
      const st = mkPrisma();
      seedAdvance(st);
      const svc = makeService(st);
      await expect(
        svc.createDistribution({
          projectId: 'p1',
          toUserId: 'master1',
          amount: 1_000_00,
          actorUserId: 'customer1',
        }),
      ).rejects.toThrow(ForbiddenError);
    });

    it('recipient не master → InvalidInputError', async () => {
      const st = mkPrisma();
      seedAdvance(st);
      const svc = makeService(st);
      await expect(
        svc.createDistribution({
          projectId: 'p1',
          toUserId: 'outsider',
          amount: 1_000_00,
          actorUserId: 'foreman1',
        }),
      ).rejects.toThrow(InvalidInputError);
    });

    it('projectId не передан и parentPaymentId тоже — InvalidInputError', async () => {
      const st = mkPrisma();
      const svc = makeService(st);
      await expect(
        svc.createDistribution({
          toUserId: 'master1',
          amount: 1_000_00,
          actorUserId: 'foreman1',
        }),
      ).rejects.toThrow(InvalidInputError);
    });

    it('archived проект → ConflictError', async () => {
      const st = mkPrisma();
      st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'archived' });
      st.memberships.push({
        projectId: 'p1',
        userId: 'foreman1',
        role: 'foreman',
        removedAt: null,
      });
      st.memberships.push({
        projectId: 'p1',
        userId: 'master1',
        role: 'master',
        removedAt: null,
      });
      const svc = makeService(st);
      await expect(
        svc.createDistribution({
          projectId: 'p1',
          toUserId: 'master1',
          amount: 1_000_00,
          actorUserId: 'foreman1',
        }),
      ).rejects.toThrow(ConflictError);
    });

    it('self-payment запрещён (foreman пытается заплатить самому себе)', async () => {
      const st = mkPrisma();
      seedAdvance(st);
      const svc = makeService(st);
      await expect(
        svc.createDistribution({
          projectId: 'p1',
          toUserId: 'foreman1',
          amount: 1_000_00,
          actorUserId: 'foreman1',
        }),
      ).rejects.toThrow(ForbiddenError);
    });
  });
});

describe('PaymentsService.listForProject', () => {
  const seed = (st: ReturnType<typeof mkPrisma>) => {
    st.projects.set('p1', { id: 'p1', ownerId: 'c1', status: 'active' });
    st.payments.set('a1', {
      id: 'a1',
      projectId: 'p1',
      stageId: null,
      parentPaymentId: null,
      kind: 'advance',
      fromUserId: 'c1',
      toUserId: 'f1',
      amount: BigInt(50_000_00),
      comment: null,
      photoKey: null,
      idempotencyKey: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    st.payments.set('d1', {
      id: 'd1',
      projectId: 'p1',
      stageId: null,
      parentPaymentId: 'a1',
      kind: 'distribution',
      fromUserId: 'f1',
      toUserId: 'm1',
      amount: BigInt(20_000_00),
      comment: null,
      photoKey: null,
      idempotencyKey: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  };

  it('owner видит все платежи проекта', async () => {
    const st = mkPrisma();
    seed(st);
    const svc = makeService(st);
    const rows = await svc.listForProject('p1', { userId: 'c1', isOwner: true });
    expect(rows.map((r) => r.id).sort()).toEqual(['a1', 'd1']);
  });

  it('master видит только свои платежи', async () => {
    const st = mkPrisma();
    seed(st);
    const svc = makeService(st);
    const rows = await svc.listForProject('p1', {
      userId: 'm1',
      membershipRole: 'master',
    });
    expect(rows.map((r) => r.id)).toEqual(['d1']);
  });

  it('outsider не видит ничего', async () => {
    const st = mkPrisma();
    seed(st);
    const svc = makeService(st);
    const rows = await svc.listForProject('p1', { userId: 'x' });
    expect(rows).toEqual([]);
  });
});
