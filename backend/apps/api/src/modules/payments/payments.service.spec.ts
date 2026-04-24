import { PaymentsService } from './payments.service';
import { FeedService } from '../feed/feed.service';
import {
  ConflictError,
  FixedClock,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';

const NOW = new Date('2026-07-10T10:00:00Z');

type ProjectRow = { id: string; ownerId: string; status: 'active' | 'archived' };
type MembershipRow = {
  projectId: string;
  userId: string;
  role: 'customer' | 'representative' | 'foreman' | 'master';
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
  resolvedAmount: bigint | null;
  status: 'pending' | 'confirmed' | 'disputed' | 'resolved' | 'cancelled';
  comment?: string | null;
  photoKey?: string | null;
  idempotencyKey: string | null;
  confirmedAt: Date | null;
  disputedAt: Date | null;
  resolvedAt: Date | null;
  cancelledAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

const mkPrisma = () => {
  const projects = new Map<string, ProjectRow>();
  const memberships: MembershipRow[] = [];
  const payments = new Map<string, PaymentRow>();
  const disputes: any[] = [];
  let pSeq = 0;

  const prisma: any = {
    project: {
      findUnique: jest.fn(({ where }: any) => projects.get(where.id) ?? null),
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
    payment: {
      findUnique: jest.fn(({ where, include }: any) => {
        const p = payments.get(where.id);
        if (!p) return null;
        if (include?.children) {
          const children = [...payments.values()].filter((c) => c.parentPaymentId === p.id);
          return { ...p, children, disputes: disputes.filter((d) => d.paymentId === p.id) };
        }
        return p;
      }),
      findMany: jest.fn(({ where }: any) => {
        return [...payments.values()].filter((p) => {
          if (where.projectId && p.projectId !== where.projectId) return false;
          if (where.status) {
            if (where.status.in) {
              if (!where.status.in.includes(p.status)) return false;
            } else if (p.status !== where.status) return false;
          }
          if (where.kind && p.kind !== where.kind) return false;
          return true;
        });
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
          resolvedAmount: null,
          status: data.status ?? 'pending',
          comment: data.comment ?? null,
          photoKey: data.photoKey ?? null,
          idempotencyKey: data.idempotencyKey ?? null,
          confirmedAt: null,
          disputedAt: null,
          resolvedAt: null,
          cancelledAt: null,
          createdAt: now,
          updatedAt: now,
        };
        payments.set(row.id, row);
        return row;
      }),
      update: jest.fn(({ where, data }: any) => {
        const p = payments.get(where.id);
        if (!p) throw new Error('not found');
        Object.assign(p, data);
        return p;
      }),
      updateMany: jest.fn(({ where, data }: any) => {
        const candidates = [...payments.values()].filter((p) => {
          if (p.id !== where.id) return false;
          if (where.status && p.status !== where.status) return false;
          return true;
        });
        for (const p of candidates) Object.assign(p, data);
        return { count: candidates.length };
      }),
    },
    paymentDispute: {
      create: jest.fn(({ data }: any) => {
        const row = {
          id: `d${disputes.length + 1}`,
          ...data,
          status: 'open',
          createdAt: new Date(),
        };
        disputes.push(row);
        return row;
      }),
      updateMany: jest.fn(({ where, data }: any) => {
        const candidates = disputes.filter(
          (d) => d.paymentId === where.paymentId && d.status === where.status,
        );
        for (const d of candidates) Object.assign(d, data);
        return { count: candidates.length };
      }),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };
  return { prisma: prisma as unknown as PrismaService, projects, memberships, payments, disputes };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

describe('PaymentsService.createAdvance', () => {
  it('создаёт pending advance и эмитит payment_created', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    const feed = mkFeed();
    const svc = new PaymentsService(st.prisma, feed, new FixedClock(NOW));
    const p = await svc.createAdvance({
      projectId: 'p1',
      toUserId: 'foreman1',
      amount: 500_000_00,
      actorUserId: 'customer1',
      idempotencyKey: 'k-1',
    });
    expect(p.status).toBe('pending');
    expect(p.kind).toBe('advance');
    expect(Number(p.amount)).toBe(500_000_00);
    expect(feed.emit).toHaveBeenCalledWith(expect.objectContaining({ kind: 'payment_created' }));
  });

  it('amount=0 → InvalidInputError', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'c', status: 'active' });
    const svc = new PaymentsService(st.prisma, mkFeed(), new FixedClock(NOW));
    await expect(
      svc.createAdvance({ projectId: 'p1', toUserId: 'x', amount: 0, actorUserId: 'c' }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('получатель не foreman → InvalidInputError', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'c', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'm1', role: 'master' });
    const svc = new PaymentsService(st.prisma, mkFeed(), new FixedClock(NOW));
    await expect(
      svc.createAdvance({ projectId: 'p1', toUserId: 'm1', amount: 100, actorUserId: 'c' }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('project archived → Conflict', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'c', status: 'archived' });
    const svc = new PaymentsService(st.prisma, mkFeed(), new FixedClock(NOW));
    await expect(
      svc.createAdvance({ projectId: 'p1', toUserId: 'f', amount: 100, actorUserId: 'c' }),
    ).rejects.toThrow(ConflictError);
  });
});

describe('PaymentsService.confirm (двустороннее подтверждение)', () => {
  it('только получатель может подтвердить, status pending → confirmed, emit + budget_updated', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    const feed = mkFeed();
    const svc = new PaymentsService(st.prisma, feed, new FixedClock(NOW));
    const p = await svc.createAdvance({
      projectId: 'p1',
      toUserId: 'foreman1',
      amount: 100_000_00,
      actorUserId: 'customer1',
    });
    const confirmed = await svc.confirm(p.id, 'foreman1');
    expect(confirmed.status).toBe('confirmed');
    expect(confirmed.confirmedAt).toEqual(NOW);
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).toContain('payment_confirmed');
    expect(kinds).toContain('budget_updated');
  });

  it('отправитель пытается подтвердить → 403', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    const svc = new PaymentsService(st.prisma, mkFeed(), new FixedClock(NOW));
    const p = await svc.createAdvance({
      projectId: 'p1',
      toUserId: 'foreman1',
      amount: 100,
      actorUserId: 'customer1',
    });
    await expect(svc.confirm(p.id, 'customer1')).rejects.toThrow(ForbiddenError);
  });

  it('повторный confirm → Conflict', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    const svc = new PaymentsService(st.prisma, mkFeed(), new FixedClock(NOW));
    const p = await svc.createAdvance({
      projectId: 'p1',
      toUserId: 'foreman1',
      amount: 100,
      actorUserId: 'customer1',
    });
    await svc.confirm(p.id, 'foreman1');
    await expect(svc.confirm(p.id, 'foreman1')).rejects.toThrow(ConflictError);
  });
});

describe('PaymentsService.createDistribution', () => {
  const setupConfirmedAdvance = async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    st.memberships.push({ projectId: 'p1', userId: 'master1', role: 'master' });
    st.memberships.push({ projectId: 'p1', userId: 'master2', role: 'master' });
    st.memberships.push({ projectId: 'p1', userId: 'master3', role: 'master' });
    const svc = new PaymentsService(st.prisma, mkFeed(), new FixedClock(NOW));
    const advance = await svc.createAdvance({
      projectId: 'p1',
      toUserId: 'foreman1',
      amount: 500_000_00,
      actorUserId: 'customer1',
    });
    await svc.confirm(advance.id, 'foreman1');
    return { st, svc, advanceId: advance.id };
  };

  it('foreman распределяет → создаётся distribution, emit payment_distributed', async () => {
    const { svc, advanceId } = await setupConfirmedAdvance();
    const d = await svc.createDistribution({
      parentPaymentId: advanceId,
      toUserId: 'master1',
      amount: 100_000_00,
      actorUserId: 'foreman1',
    });
    expect(d.kind).toBe('distribution');
    expect(d.parentPaymentId).toBe(advanceId);
    expect(d.warning).toBeUndefined();
  });

  it('не получатель advance → 403 (только foreman=parent.toUserId)', async () => {
    const { st, svc, advanceId } = await setupConfirmedAdvance();
    // customer пытается распределить чужой advance
    await expect(
      svc.createDistribution({
        parentPaymentId: advanceId,
        toUserId: 'master1',
        amount: 100,
        actorUserId: 'customer1',
      }),
    ).rejects.toThrow(ForbiddenError);
    expect(st.payments.size).toBe(1); // только исходный advance
  });

  it('parent не confirmed → Conflict', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'c', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'f1', role: 'foreman' });
    st.memberships.push({ projectId: 'p1', userId: 'm1', role: 'master' });
    const svc = new PaymentsService(st.prisma, mkFeed(), new FixedClock(NOW));
    const advance = await svc.createAdvance({
      projectId: 'p1',
      toUserId: 'f1',
      amount: 1000,
      actorUserId: 'c',
    });
    // не подтверждаем — сразу distribute
    await expect(
      svc.createDistribution({
        parentPaymentId: advance.id,
        toUserId: 'm1',
        amount: 500,
        actorUserId: 'f1',
      }),
    ).rejects.toThrow(ConflictError);
  });

  it('сумма > остатка parent → warning, НЕ блок (gaps §4.2)', async () => {
    const { svc, advanceId } = await setupConfirmedAdvance();
    await svc.createDistribution({
      parentPaymentId: advanceId,
      toUserId: 'master1',
      amount: 300_000_00,
      actorUserId: 'foreman1',
    });
    await svc.createDistribution({
      parentPaymentId: advanceId,
      toUserId: 'master2',
      amount: 150_000_00,
      actorUserId: 'foreman1',
    });
    // На этот момент active = 450k. Добавим 100k → 550k > 500k
    const overflow = await svc.createDistribution({
      parentPaymentId: advanceId,
      toUserId: 'master3',
      amount: 100_000_00,
      actorUserId: 'foreman1',
    });
    expect(overflow.warning).toBe('exceeds_parent_remaining');
  });

  it('распределение по 3 мастерам 100k+100k+100k — без warning, все pending', async () => {
    const { st, svc, advanceId } = await setupConfirmedAdvance();
    for (const m of ['master1', 'master2', 'master3']) {
      await svc.createDistribution({
        parentPaymentId: advanceId,
        toUserId: m,
        amount: 100_000_00,
        actorUserId: 'foreman1',
      });
    }
    const distributions = [...st.payments.values()].filter((p) => p.kind === 'distribution');
    expect(distributions).toHaveLength(3);
    expect(distributions.every((p) => p.status === 'pending')).toBe(true);
  });
});

describe('PaymentsService.dispute + resolve', () => {
  it('сторона открывает спор, customer резолвит с коррекцией', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    const feed = mkFeed();
    const svc = new PaymentsService(st.prisma, feed, new FixedClock(NOW));
    const p = await svc.createAdvance({
      projectId: 'p1',
      toUserId: 'foreman1',
      amount: 100_000_00,
      actorUserId: 'customer1',
    });
    await svc.confirm(p.id, 'foreman1');
    const disputed = await svc.dispute(p.id, 'неверная сумма', 'foreman1');
    expect(disputed.status).toBe('disputed');
    const resolved = await svc.resolve(p.id, {
      resolution: 'корректировка',
      adjustAmount: 95_000_00,
      actorUserId: 'customer1',
    });
    expect(resolved.status).toBe('resolved');
    expect(Number(resolved.resolvedAmount)).toBe(95_000_00);
  });

  it('third party не может dispute → 403', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    const svc = new PaymentsService(st.prisma, mkFeed(), new FixedClock(NOW));
    const p = await svc.createAdvance({
      projectId: 'p1',
      toUserId: 'foreman1',
      amount: 100,
      actorUserId: 'customer1',
    });
    await expect(svc.dispute(p.id, 'x', 'stranger')).rejects.toThrow(ForbiddenError);
  });

  it('resolve не disputed → Conflict', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    const svc = new PaymentsService(st.prisma, mkFeed(), new FixedClock(NOW));
    const p = await svc.createAdvance({
      projectId: 'p1',
      toUserId: 'foreman1',
      amount: 100,
      actorUserId: 'customer1',
    });
    await expect(svc.resolve(p.id, { resolution: 'x', actorUserId: 'customer1' })).rejects.toThrow(
      ConflictError,
    );
  });
});

describe('PaymentsService.cancel', () => {
  it('fromUserId может отменить pending, статус → cancelled', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    const svc = new PaymentsService(st.prisma, mkFeed(), new FixedClock(NOW));
    const p = await svc.createAdvance({
      projectId: 'p1',
      toUserId: 'foreman1',
      amount: 100,
      actorUserId: 'customer1',
    });
    const cancelled = await svc.cancel(p.id, 'customer1');
    expect(cancelled.status).toBe('cancelled');
  });

  it('после confirmed cancel невозможен → Conflict', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'customer1', status: 'active' });
    st.memberships.push({ projectId: 'p1', userId: 'foreman1', role: 'foreman' });
    const svc = new PaymentsService(st.prisma, mkFeed(), new FixedClock(NOW));
    const p = await svc.createAdvance({
      projectId: 'p1',
      toUserId: 'foreman1',
      amount: 100,
      actorUserId: 'customer1',
    });
    await svc.confirm(p.id, 'foreman1');
    await expect(svc.cancel(p.id, 'customer1')).rejects.toThrow(ConflictError);
  });
});

describe('PaymentsService.get not found', () => {
  it('404 на несуществующий id', async () => {
    const st = mkPrisma();
    const svc = new PaymentsService(st.prisma, mkFeed(), new FixedClock(NOW));
    await expect(svc.get('missing')).rejects.toThrow(NotFoundError);
  });
});
