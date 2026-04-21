import { ApprovalsService } from './approvals.service';
import { FeedService } from '../feed/feed.service';
import { ProgressCalculator } from '../stages/progress-calculator';
import {
  ConflictError,
  FixedClock,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';

const NOW = new Date('2026-06-10T12:00:00Z');

type ProjectRow = {
  id: string;
  ownerId: string;
  status: 'active' | 'archived';
  planApproved?: boolean;
  requiresPlanApproval?: boolean;
};

type StageRow = {
  id: string;
  projectId: string;
  status: 'pending' | 'active' | 'paused' | 'review' | 'done' | 'rejected';
  foremanIds?: string[];
  plannedEnd?: Date | null;
  originalEnd?: Date | null;
  workBudget?: bigint;
  planApproved?: boolean;
};

type StepRow = {
  id: string;
  stageId: string;
  status: 'pending' | 'in_progress' | 'done' | 'pending_approval' | 'rejected';
  price: bigint | null;
};

type ApprovalRow = {
  id: string;
  scope: 'plan' | 'step' | 'extra_work' | 'deadline_change' | 'stage_accept';
  projectId: string;
  stageId: string | null;
  stepId: string | null;
  payload: Record<string, any>;
  requestedById: string;
  addresseeId: string;
  status: 'pending' | 'approved' | 'rejected' | 'cancelled';
  attemptNumber: number;
  decidedAt: Date | null;
  decidedById: string | null;
  decisionComment: string | null;
  createdAt: Date;
  updatedAt: Date;
};

const mkPrisma = () => {
  const projects = new Map<string, ProjectRow>();
  const stages = new Map<string, StageRow>();
  const steps = new Map<string, StepRow>();
  const approvals = new Map<string, ApprovalRow>();
  const attempts: any[] = [];
  const memberships: any[] = [];
  let aSeq = 0;
  let atSeq = 0;

  const prisma: any = {
    project: {
      findUnique: jest.fn(({ where }: any) => projects.get(where.id) ?? null),
      update: jest.fn(({ where, data }: any) => {
        const p = projects.get(where.id);
        if (p) Object.assign(p, data);
        return p;
      }),
    },
    stage: {
      findUnique: jest.fn(({ where }: any) => stages.get(where.id) ?? null),
      update: jest.fn(({ where, data }: any) => {
        const s = stages.get(where.id);
        if (!s) throw new Error('stage not found');
        for (const [k, v] of Object.entries(data)) {
          if (k === 'workBudget' && typeof v === 'object' && v && 'increment' in (v as any)) {
            s.workBudget = (s.workBudget ?? BigInt(0)) + BigInt((v as any).increment);
          } else {
            (s as any)[k] = v;
          }
        }
        return s;
      }),
      updateMany: jest.fn(({ where, data }: any) => {
        const list = [...stages.values()].filter((s) => s.projectId === where.projectId);
        for (const s of list) Object.assign(s, data);
        return { count: list.length };
      }),
    },
    step: {
      findUnique: jest.fn(({ where }: any) => steps.get(where.id) ?? null),
      update: jest.fn(({ where, data }: any) => {
        const s = steps.get(where.id);
        if (!s) throw new Error('step not found');
        Object.assign(s, data);
        return s;
      }),
    },
    approval: {
      create: jest.fn(({ data }: any) => {
        const now = new Date();
        const row: ApprovalRow = {
          id: `ap${++aSeq}`,
          scope: data.scope,
          projectId: data.projectId,
          stageId: data.stageId ?? null,
          stepId: data.stepId ?? null,
          payload: data.payload ?? {},
          requestedById: data.requestedById,
          addresseeId: data.addresseeId,
          status: data.status ?? 'pending',
          attemptNumber: data.attemptNumber ?? 1,
          decidedAt: null,
          decidedById: null,
          decisionComment: null,
          createdAt: now,
          updatedAt: now,
        };
        approvals.set(row.id, row);
        return row;
      }),
      findUnique: jest.fn(({ where, include }: any) => {
        const a = approvals.get(where.id);
        if (!a) return null;
        if (include?.stage || include?.project) {
          return {
            ...a,
            stage: a.stageId
              ? {
                  foremanIds: stages.get(a.stageId)?.foremanIds ?? [],
                  projectId: a.projectId,
                }
              : null,
            project: { ownerId: projects.get(a.projectId)?.ownerId ?? 'owner' },
          };
        }
        return a;
      }),
      update: jest.fn(({ where, data }: any) => {
        const a = approvals.get(where.id);
        if (!a) throw new Error('approval not found');
        Object.assign(a, data);
        return a;
      }),
      findMany: jest.fn(({ where }: any) => {
        return [...approvals.values()].filter((a) => {
          if (where.projectId && a.projectId !== where.projectId) return false;
          if (where.scope && a.scope !== where.scope) return false;
          if (where.status && a.status !== where.status) return false;
          if (where.addresseeId && a.addresseeId !== where.addresseeId) return false;
          return true;
        });
      }),
    },
    approvalAttempt: {
      create: jest.fn(({ data }: any) => {
        const row = { id: `at${++atSeq}`, createdAt: new Date(), ...data };
        attempts.push(row);
        return row;
      }),
    },
    approvalAttachment: {
      create: jest.fn(({ data }: any) => ({ id: 'att1', ...data })),
    },
    membership: {
      findFirst: jest.fn(
        ({ where }: any) =>
          memberships.find(
            (m) =>
              m.projectId === where.projectId && m.userId === where.userId && m.role === where.role,
          ) ?? null,
      ),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };
  return {
    prisma: prisma as unknown as PrismaService,
    projects,
    stages,
    steps,
    approvals,
    attempts,
    memberships,
  };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;
const mkCalc = (): ProgressCalculator =>
  ({
    stageSemaphore: jest.fn(),
    recalcStage: jest.fn().mockResolvedValue(undefined),
    recalcProject: jest.fn().mockResolvedValue(undefined),
    computeProjectProgress: jest.fn(),
    computeProjectSemaphore: jest.fn(),
    computeStageProgress: jest.fn().mockResolvedValue(0),
  }) as any;

describe('ApprovalsService.request — валидация scope', () => {
  it('scope=step без stepId → InvalidInputError', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    await expect(
      svc.request({
        scope: 'step',
        projectId: 'p1',
        addresseeId: 'owner',
        requestedById: 'f1',
      }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('scope=stage_accept требует stage.status=review', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    st.stages.set('s1', { id: 's1', projectId: 'p1', status: 'active' });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    await expect(
      svc.request({
        scope: 'stage_accept',
        projectId: 'p1',
        stageId: 's1',
        addresseeId: 'owner',
        requestedById: 'f1',
      }),
    ).rejects.toThrow(ConflictError);
  });

  it('scope=deadline_change требует payload.newEnd в будущем', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    st.stages.set('s1', { id: 's1', projectId: 'p1', status: 'active' });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    await expect(
      svc.request({
        scope: 'deadline_change',
        projectId: 'p1',
        stageId: 's1',
        addresseeId: 'owner',
        payload: { newEnd: '2020-01-01' },
        requestedById: 'f1',
      }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('archived project — request отклоняется', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'archived' });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    await expect(
      svc.request({
        scope: 'plan',
        projectId: 'p1',
        addresseeId: 'owner',
        requestedById: 'f1',
      }),
    ).rejects.toThrow(ConflictError);
  });

  it('успешный request: эмитит approval_requested, создаёт Attempt', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    const feed = mkFeed();
    const svc = new ApprovalsService(st.prisma, feed, mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'plan',
      projectId: 'p1',
      addresseeId: 'owner',
      requestedById: 'f1',
    });
    expect(a.status).toBe('pending');
    expect(a.attemptNumber).toBe(1);
    expect(feed.emit).toHaveBeenCalledWith(expect.objectContaining({ kind: 'approval_requested' }));
    expect(st.attempts).toHaveLength(1);
    expect(st.attempts[0].action).toBe('created');
  });
});

describe('ApprovalsService.decide — применение эффектов', () => {
  it('plan approved → project.planApproved=true, все stages.planApproved=true, emit plan_approved', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    st.stages.set('s1', { id: 's1', projectId: 'p1', status: 'pending' });
    st.stages.set('s2', { id: 's2', projectId: 'p1', status: 'pending' });
    const feed = mkFeed();
    const svc = new ApprovalsService(st.prisma, feed, mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'plan',
      projectId: 'p1',
      addresseeId: 'owner',
      requestedById: 'f1',
    });
    const res = await svc.decide(a.id, {
      actorUserId: 'owner',
      actorSystemRole: 'customer',
      decision: 'approved',
    });
    expect(res.status).toBe('approved');
    expect(st.projects.get('p1')!.planApproved).toBe(true);
    expect(st.stages.get('s1')!.planApproved).toBe(true);
    expect(st.stages.get('s2')!.planApproved).toBe(true);
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).toContain('plan_approved');
  });

  it('stage_accept approved → stage.status=done + doneAt; emit stage_accepted', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    st.stages.set('s1', { id: 's1', projectId: 'p1', status: 'review' });
    const feed = mkFeed();
    const svc = new ApprovalsService(st.prisma, feed, mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'stage_accept',
      projectId: 'p1',
      stageId: 's1',
      addresseeId: 'owner',
      requestedById: 'f1',
    });
    const res = await svc.decide(a.id, {
      actorUserId: 'owner',
      actorSystemRole: 'customer',
      decision: 'approved',
    });
    expect(res.status).toBe('approved');
    expect(st.stages.get('s1')!.status).toBe('done');
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).toContain('stage_accepted');
  });

  it('stage_accept rejected → stage.status=rejected; emit stage_rejected_by_customer', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    st.stages.set('s1', { id: 's1', projectId: 'p1', status: 'review' });
    const feed = mkFeed();
    const svc = new ApprovalsService(st.prisma, feed, mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'stage_accept',
      projectId: 'p1',
      stageId: 's1',
      addresseeId: 'owner',
      requestedById: 'f1',
    });
    await svc.decide(a.id, {
      actorUserId: 'owner',
      actorSystemRole: 'customer',
      decision: 'rejected',
      comment: 'плохо сделано',
    });
    expect(st.stages.get('s1')!.status).toBe('rejected');
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).toContain('stage_rejected_by_customer');
  });

  it('extra_work approved → stage.workBudget += price, step.status=pending, emit budget_updated', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    st.stages.set('s1', {
      id: 's1',
      projectId: 'p1',
      status: 'active',
      workBudget: BigInt(100000),
    });
    st.steps.set('st1', {
      id: 'st1',
      stageId: 's1',
      status: 'pending_approval',
      price: BigInt(12000),
    });
    const feed = mkFeed();
    const svc = new ApprovalsService(st.prisma, feed, mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'extra_work',
      projectId: 'p1',
      stageId: 's1',
      stepId: 'st1',
      addresseeId: 'owner',
      payload: { stepId: 'st1', price: 12000 },
      requestedById: 'foreman1',
    });
    await svc.decide(a.id, {
      actorUserId: 'owner',
      actorSystemRole: 'customer',
      decision: 'approved',
    });
    expect(st.stages.get('s1')!.workBudget).toBe(BigInt(112000));
    expect(st.steps.get('st1')!.status).toBe('pending');
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).toContain('budget_updated');
  });

  it('extra_work rejected → step.status=rejected, бюджет НЕ меняется', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    st.stages.set('s1', {
      id: 's1',
      projectId: 'p1',
      status: 'active',
      workBudget: BigInt(100000),
    });
    st.steps.set('st1', {
      id: 'st1',
      stageId: 's1',
      status: 'pending_approval',
      price: BigInt(12000),
    });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'extra_work',
      projectId: 'p1',
      stageId: 's1',
      stepId: 'st1',
      addresseeId: 'owner',
      payload: { stepId: 'st1', price: 12000 },
      requestedById: 'foreman1',
    });
    await svc.decide(a.id, {
      actorUserId: 'owner',
      actorSystemRole: 'customer',
      decision: 'rejected',
      comment: 'не нужно',
    });
    expect(st.stages.get('s1')!.workBudget).toBe(BigInt(100000));
    expect(st.steps.get('st1')!.status).toBe('rejected');
  });

  it('deadline_change approved → stage.plannedEnd и originalEnd обновлены + 2 emit', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    st.stages.set('s1', {
      id: 's1',
      projectId: 'p1',
      status: 'active',
      plannedEnd: new Date('2026-07-01'),
      originalEnd: new Date('2026-07-01'),
    });
    const feed = mkFeed();
    const svc = new ApprovalsService(st.prisma, feed, mkCalc(), new FixedClock(NOW));
    const newEndIso = '2026-08-15T00:00:00.000Z';
    const a = await svc.request({
      scope: 'deadline_change',
      projectId: 'p1',
      stageId: 's1',
      addresseeId: 'owner',
      payload: { newEnd: newEndIso, reason: 'поставка задерживается' },
      requestedById: 'foreman1',
    });
    await svc.decide(a.id, {
      actorUserId: 'owner',
      actorSystemRole: 'customer',
      decision: 'approved',
    });
    const s = st.stages.get('s1')!;
    expect(s.plannedEnd?.toISOString()).toBe(newEndIso);
    expect(s.originalEnd?.toISOString()).toBe(newEndIso);
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).toContain('deadline_changed');
    expect(kinds).toContain('stage_deadline_recalculated');
  });

  it('reject без comment → InvalidInputError', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'plan',
      projectId: 'p1',
      addresseeId: 'owner',
      requestedById: 'f1',
    });
    await expect(
      svc.decide(a.id, {
        actorUserId: 'owner',
        actorSystemRole: 'customer',
        decision: 'rejected',
      }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('повторный decide на уже решённый → Conflict', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'plan',
      projectId: 'p1',
      addresseeId: 'owner',
      requestedById: 'f1',
    });
    await svc.decide(a.id, {
      actorUserId: 'owner',
      actorSystemRole: 'customer',
      decision: 'approved',
    });
    await expect(
      svc.decide(a.id, {
        actorUserId: 'owner',
        actorSystemRole: 'customer',
        decision: 'approved',
      }),
    ).rejects.toThrow(ConflictError);
  });
});

describe('ApprovalsService — gaps §3.3 (customer не решает мимо бригадира)', () => {
  it('scope=step, адресат = foreman, customer-owner не может согласовать мимо', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    st.stages.set('s1', {
      id: 's1',
      projectId: 'p1',
      status: 'active',
      foremanIds: ['f1'],
    });
    st.steps.set('st1', { id: 'st1', stageId: 's1', status: 'in_progress', price: null });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'step',
      projectId: 'p1',
      stageId: 's1',
      stepId: 'st1',
      addresseeId: 'f1',
      requestedById: 'master1',
    });
    await expect(
      svc.decide(a.id, {
        actorUserId: 'owner',
        actorSystemRole: 'customer',
        decision: 'approved',
      }),
    ).rejects.toThrow(ForbiddenError);
  });

  it('foreman (addressee) сам принимает → ok', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    st.stages.set('s1', {
      id: 's1',
      projectId: 'p1',
      status: 'active',
      foremanIds: ['f1'],
    });
    st.steps.set('st1', { id: 'st1', stageId: 's1', status: 'in_progress', price: null });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'step',
      projectId: 'p1',
      stageId: 's1',
      stepId: 'st1',
      addresseeId: 'f1',
      requestedById: 'master1',
    });
    const res = await svc.decide(a.id, {
      actorUserId: 'f1',
      actorSystemRole: 'contractor',
      decision: 'approved',
    });
    expect(res.status).toBe('approved');
    expect(st.steps.get('st1')!.status).toBe('done');
  });
});

describe('ApprovalsService.resubmit', () => {
  it('только автор может resubmit; attemptNumber++, status=pending', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'plan',
      projectId: 'p1',
      addresseeId: 'owner',
      requestedById: 'foreman1',
    });
    await svc.decide(a.id, {
      actorUserId: 'owner',
      actorSystemRole: 'customer',
      decision: 'rejected',
      comment: 'сдвиньте',
    });
    const resubmitted = await svc.resubmit(a.id, {
      actorUserId: 'foreman1',
      payload: { adjusted: true },
    });
    expect(resubmitted.status).toBe('pending');
    expect(resubmitted.attemptNumber).toBe(2);
  });

  it('не автор → ForbiddenError', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'plan',
      projectId: 'p1',
      addresseeId: 'owner',
      requestedById: 'foreman1',
    });
    await svc.decide(a.id, {
      actorUserId: 'owner',
      actorSystemRole: 'customer',
      decision: 'rejected',
      comment: 'x',
    });
    await expect(svc.resubmit(a.id, { actorUserId: 'stranger' })).rejects.toThrow(ForbiddenError);
  });

  it('resubmit не из rejected → Conflict', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'plan',
      projectId: 'p1',
      addresseeId: 'owner',
      requestedById: 'foreman1',
    });
    await expect(svc.resubmit(a.id, { actorUserId: 'foreman1' })).rejects.toThrow(ConflictError);
  });
});

describe('ApprovalsService.cancel', () => {
  it('автор отменяет pending → status=cancelled, emit approval_cancelled', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    const feed = mkFeed();
    const svc = new ApprovalsService(st.prisma, feed, mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'plan',
      projectId: 'p1',
      addresseeId: 'owner',
      requestedById: 'foreman1',
    });
    const res = await svc.cancel(a.id, 'foreman1');
    expect(res.status).toBe('cancelled');
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).toContain('approval_cancelled');
  });

  it('не автор → 403', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'plan',
      projectId: 'p1',
      addresseeId: 'owner',
      requestedById: 'foreman1',
    });
    await expect(svc.cancel(a.id, 'stranger')).rejects.toThrow(ForbiddenError);
  });

  it('не-pending → Conflict', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'plan',
      projectId: 'p1',
      addresseeId: 'owner',
      requestedById: 'foreman1',
    });
    await svc.decide(a.id, {
      actorUserId: 'owner',
      actorSystemRole: 'customer',
      decision: 'approved',
    });
    await expect(svc.cancel(a.id, 'foreman1')).rejects.toThrow(ConflictError);
  });
});

describe('ApprovalsService — авторизация decide', () => {
  it('representative с canApprove=false → 403', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    st.memberships.push({
      projectId: 'p1',
      userId: 'rep1',
      role: 'representative',
      permissions: { canApprove: false },
    });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'plan',
      projectId: 'p1',
      addresseeId: 'owner',
      requestedById: 'foreman1',
    });
    await expect(
      svc.decide(a.id, {
        actorUserId: 'rep1',
        actorSystemRole: 'representative',
        decision: 'approved',
      }),
    ).rejects.toThrow(ForbiddenError);
  });

  it('representative с canApprove=true → ok', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    st.memberships.push({
      projectId: 'p1',
      userId: 'rep1',
      role: 'representative',
      permissions: { canApprove: true },
    });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'plan',
      projectId: 'p1',
      addresseeId: 'owner',
      requestedById: 'foreman1',
    });
    const res = await svc.decide(a.id, {
      actorUserId: 'rep1',
      actorSystemRole: 'representative',
      decision: 'approved',
    });
    expect(res.status).toBe('approved');
  });

  it('случайный пользователь → 403', async () => {
    const st = mkPrisma();
    st.projects.set('p1', { id: 'p1', ownerId: 'owner', status: 'active' });
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    const a = await svc.request({
      scope: 'plan',
      projectId: 'p1',
      addresseeId: 'owner',
      requestedById: 'foreman1',
    });
    await expect(
      svc.decide(a.id, {
        actorUserId: 'stranger',
        actorSystemRole: 'master',
        decision: 'approved',
      }),
    ).rejects.toThrow(ForbiddenError);
  });
});

describe('ApprovalsService — не найдено', () => {
  it('decide на несуществующий → 404', async () => {
    const st = mkPrisma();
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    await expect(
      svc.decide('missing', {
        actorUserId: 'owner',
        actorSystemRole: 'customer',
        decision: 'approved',
      }),
    ).rejects.toThrow(NotFoundError);
  });

  it('request в несуществующий проект → 404', async () => {
    const st = mkPrisma();
    const svc = new ApprovalsService(st.prisma, mkFeed(), mkCalc(), new FixedClock(NOW));
    await expect(
      svc.request({
        scope: 'plan',
        projectId: 'missing',
        addresseeId: 'owner',
        requestedById: 'f1',
      }),
    ).rejects.toThrow(NotFoundError);
  });
});
