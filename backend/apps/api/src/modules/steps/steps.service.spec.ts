import { StepsService } from './steps.service';
import { FeedService } from '../feed/feed.service';
import { ProgressCalculator } from '../stages/progress-calculator';
import {
  ConflictError,
  FixedClock,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';

const NOW = new Date('2026-06-10T10:00:00Z');

type StageRow = {
  id: string;
  projectId: string;
  status: 'pending' | 'active' | 'paused' | 'review' | 'done' | 'rejected';
};

type StepRow = {
  id: string;
  stageId: string;
  title: string;
  orderIndex: number;
  type: 'regular' | 'extra';
  status: 'pending' | 'in_progress' | 'done' | 'pending_approval' | 'rejected';
  price: bigint | null;
  description?: string | null;
  authorId: string;
  assigneeIds: string[];
  doneAt: Date | null;
  doneById: string | null;
  createdAt: Date;
  updatedAt: Date;
};

type MembershipRow = {
  projectId: string;
  userId: string;
  role: 'customer' | 'representative' | 'foreman' | 'master';
};

const mkPrisma = () => {
  const stages = new Map<string, StageRow>();
  const steps = new Map<string, StepRow>();
  const memberships: MembershipRow[] = [];
  let stepSeq = 0;

  const prisma: any = {
    stage: {
      findUnique: jest.fn(({ where }: any) => {
        const s = stages.get(where.id);
        if (!s) return null;
        return { ...s, project: { ownerId: `${s.projectId}-owner` } };
      }),
    },
    step: {
      findUnique: jest.fn(({ where, include }: any) => {
        const s = steps.get(where.id);
        if (!s) return null;
        if (include?.stage) {
          return {
            ...s,
            stage: {
              projectId: stages.get(s.stageId)?.projectId,
              status: stages.get(s.stageId)?.status,
            },
          };
        }
        return s;
      }),
      findMany: jest.fn(({ where }: any) =>
        [...steps.values()].filter((s) => s.stageId === where.stageId),
      ),
      count: jest.fn(({ where }: any) => {
        const list = [...steps.values()].filter((s) => {
          if (where.stageId && s.stageId !== where.stageId) return false;
          if (where.status === 'done' && s.status !== 'done') return false;
          if (where.status?.notIn) {
            if (where.status.notIn.includes(s.status)) return false;
          }
          return true;
        });
        return list.length;
      }),
      create: jest.fn(({ data }: any) => {
        const now = new Date();
        const row: StepRow = {
          id: `st${++stepSeq}`,
          stageId: data.stageId,
          title: data.title,
          orderIndex: data.orderIndex ?? 0,
          type: data.type ?? 'regular',
          status: data.status ?? 'pending',
          price: data.price ?? null,
          description: data.description ?? null,
          authorId: data.authorId,
          assigneeIds: data.assigneeIds ?? [],
          doneAt: null,
          doneById: null,
          createdAt: now,
          updatedAt: now,
        };
        steps.set(row.id, row);
        return row;
      }),
      update: jest.fn(({ where, data }: any) => {
        const s = steps.get(where.id);
        if (!s) throw new Error('step not found');
        for (const [k, v] of Object.entries(data)) {
          (s as any)[k] = v;
        }
        return s;
      }),
      delete: jest.fn(({ where }: any) => {
        const s = steps.get(where.id);
        steps.delete(where.id);
        return s;
      }),
    },
    membership: {
      findMany: jest.fn(({ where }: any) =>
        memberships.filter(
          (m) =>
            m.projectId === where.projectId &&
            m.role === where.role &&
            where.userId.in.includes(m.userId),
        ),
      ),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };
  return { prisma: prisma as unknown as PrismaService, stages, steps, memberships };
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

const mkApprovals = () =>
  ({
    request: jest.fn().mockResolvedValue({ id: 'ap-mock' }),
  }) as any;

const setupStage = (
  prismaState: ReturnType<typeof mkPrisma>,
  id: string,
  projectId: string,
  status: StageRow['status'] = 'pending',
) => prismaState.stages.set(id, { id, projectId, status });

describe('StepsService.create — регулярный шаг', () => {
  it('создаёт шаг со статусом pending и эмитит step_created (ТЗ §6.4)', async () => {
    const state = mkPrisma();
    setupStage(state, 'stage1', 'p1');
    const feed = mkFeed();
    const svc = new StepsService(state.prisma, feed, mkCalc(), new FixedClock(NOW), mkApprovals());
    const step = await svc.create({
      stageId: 'stage1',
      title: 'Снять плинтусы',
      actorUserId: 'u1',
    });
    expect(step.status).toBe('pending');
    expect(step.type).toBe('regular');
    expect(feed.emit).toHaveBeenCalledWith(
      expect.objectContaining({ kind: 'step_created', projectId: 'p1' }),
    );
  });

  it('бросает 404 если stage не найден', async () => {
    const state = mkPrisma();
    const svc = new StepsService(
      state.prisma,
      mkFeed(),
      mkCalc(),
      new FixedClock(NOW),
      mkApprovals(),
    );
    await expect(svc.create({ stageId: 'missing', title: 'X', actorUserId: 'u1' })).rejects.toThrow(
      NotFoundError,
    );
  });

  it('пустой title отклоняется', async () => {
    const state = mkPrisma();
    setupStage(state, 'stage1', 'p1');
    const svc = new StepsService(
      state.prisma,
      mkFeed(),
      mkCalc(),
      new FixedClock(NOW),
      mkApprovals(),
    );
    await expect(
      svc.create({ stageId: 'stage1', title: '   ', actorUserId: 'u1' }),
    ).rejects.toThrow(InvalidInputError);
  });
});

describe('StepsService.create — extra (доп.работа, ТЗ §4.3 + gaps §4.1)', () => {
  it('status=pending_approval, эмитит extra_work_requested, price сохранён но НЕ в бюджете стадии', async () => {
    const state = mkPrisma();
    setupStage(state, 'stage1', 'p1');
    const feed = mkFeed();
    const svc = new StepsService(state.prisma, feed, mkCalc(), new FixedClock(NOW), mkApprovals());
    const step = await svc.create({
      stageId: 'stage1',
      title: 'Ревизия розеток',
      type: 'extra',
      price: 12000,
      actorUserId: 'foreman1',
    });
    expect(step.status).toBe('pending_approval');
    expect(step.price).toBe(12000);
    expect(feed.emit).toHaveBeenCalledWith(
      expect.objectContaining({ kind: 'extra_work_requested' }),
    );
    // Нет эмита step_created для extra — только extra_work_requested
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).not.toContain('step_created');
  });

  it('extra без price отклоняется', async () => {
    const state = mkPrisma();
    setupStage(state, 'stage1', 'p1');
    const svc = new StepsService(
      state.prisma,
      mkFeed(),
      mkCalc(),
      new FixedClock(NOW),
      mkApprovals(),
    );
    await expect(
      svc.create({ stageId: 'stage1', title: 'X', type: 'extra', actorUserId: 'u1' }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('extra с price=0 отклоняется', async () => {
    const state = mkPrisma();
    setupStage(state, 'stage1', 'p1');
    const svc = new StepsService(
      state.prisma,
      mkFeed(),
      mkCalc(),
      new FixedClock(NOW),
      mkApprovals(),
    );
    await expect(
      svc.create({ stageId: 'stage1', title: 'X', type: 'extra', price: 0, actorUserId: 'u1' }),
    ).rejects.toThrow(InvalidInputError);
  });
});

describe('StepsService.create — пересчёт прогресса (gaps §2.3)', () => {
  it('в активном этапе эмитит progress_recalculated_on_step_change', async () => {
    const state = mkPrisma();
    setupStage(state, 'stage1', 'p1', 'active');
    const feed = mkFeed();
    const svc = new StepsService(state.prisma, feed, mkCalc(), new FixedClock(NOW), mkApprovals());
    await svc.create({ stageId: 'stage1', title: 'X', actorUserId: 'u1' });
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).toContain('progress_recalculated_on_step_change');
  });

  it('в pending этапе НЕ эмитит progress_recalculated_on_step_change', async () => {
    const state = mkPrisma();
    setupStage(state, 'stage1', 'p1', 'pending');
    const feed = mkFeed();
    const svc = new StepsService(state.prisma, feed, mkCalc(), new FixedClock(NOW), mkApprovals());
    await svc.create({ stageId: 'stage1', title: 'X', actorUserId: 'u1' });
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).not.toContain('progress_recalculated_on_step_change');
  });

  it('recalcStage вызывается в транзакции для создания', async () => {
    const state = mkPrisma();
    setupStage(state, 'stage1', 'p1', 'active');
    const calc = mkCalc();
    const svc = new StepsService(state.prisma, mkFeed(), calc, new FixedClock(NOW), mkApprovals());
    await svc.create({ stageId: 'stage1', title: 'X', actorUserId: 'u1' });
    expect(calc.recalcStage).toHaveBeenCalledWith('stage1', expect.anything());
  });
});

describe('StepsService.complete', () => {
  it('done: doneAt=clock.now(), вызов recalcStage', async () => {
    const state = mkPrisma();
    setupStage(state, 'stage1', 'p1', 'active');
    const clock = new FixedClock(NOW);
    const calc = mkCalc();
    const svc = new StepsService(state.prisma, mkFeed(), calc, clock, mkApprovals());
    const created = await svc.create({ stageId: 'stage1', title: 'X', actorUserId: 'u1' });
    const done = await svc.complete(created.id, 'u2');
    expect(done.status).toBe('done');
    expect(done.doneAt).toEqual(NOW);
    expect(done.doneById).toBe('u2');
    expect(calc.recalcStage).toHaveBeenCalled();
  });

  it('extra в pending_approval нельзя завершить до одобрения', async () => {
    const state = mkPrisma();
    setupStage(state, 'stage1', 'p1');
    const svc = new StepsService(
      state.prisma,
      mkFeed(),
      mkCalc(),
      new FixedClock(NOW),
      mkApprovals(),
    );
    const extra = await svc.create({
      stageId: 'stage1',
      title: 'X',
      type: 'extra',
      price: 1000,
      actorUserId: 'u1',
    });
    await expect(svc.complete(extra.id, 'u2')).rejects.toThrow(ConflictError);
  });

  it('уже done → Conflict', async () => {
    const state = mkPrisma();
    setupStage(state, 'stage1', 'p1', 'active');
    const svc = new StepsService(
      state.prisma,
      mkFeed(),
      mkCalc(),
      new FixedClock(NOW),
      mkApprovals(),
    );
    const s = await svc.create({ stageId: 'stage1', title: 'X', actorUserId: 'u' });
    await svc.complete(s.id, 'u');
    await expect(svc.complete(s.id, 'u')).rejects.toThrow(ConflictError);
  });
});

describe('StepsService.delete', () => {
  it('удаляет шаг и вызывает recalcStage в активной стадии', async () => {
    const state = mkPrisma();
    setupStage(state, 'stage1', 'p1', 'active');
    const feed = mkFeed();
    const calc = mkCalc();
    const svc = new StepsService(state.prisma, feed, calc, new FixedClock(NOW), mkApprovals());
    const s = await svc.create({ stageId: 'stage1', title: 'X', actorUserId: 'u' });
    await svc.delete(s.id, 'u');
    expect(state.steps.size).toBe(0);
    expect(calc.recalcStage).toHaveBeenCalledWith('stage1', expect.anything());
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).toContain('step_deleted');
    expect(kinds).toContain('progress_recalculated_on_step_change');
  });
});

describe('StepsService.reorder', () => {
  it('переставляет шаги только того же stage', async () => {
    const state = mkPrisma();
    setupStage(state, 'stage1', 'p1');
    const svc = new StepsService(
      state.prisma,
      mkFeed(),
      mkCalc(),
      new FixedClock(NOW),
      mkApprovals(),
    );
    const s1 = await svc.create({ stageId: 'stage1', title: 'A', actorUserId: 'u' });
    const s2 = await svc.create({ stageId: 'stage1', title: 'B', actorUserId: 'u' });
    await svc.reorder(
      'stage1',
      [
        { id: s1.id, orderIndex: 1 },
        { id: s2.id, orderIndex: 0 },
      ],
      'u',
    );
    const freshA = state.steps.get(s1.id)!;
    const freshB = state.steps.get(s2.id)!;
    expect(freshA.orderIndex).toBe(1);
    expect(freshB.orderIndex).toBe(0);
  });

  it('шаг из чужого stage → InvalidInputError', async () => {
    const state = mkPrisma();
    setupStage(state, 'stage1', 'p1');
    const svc = new StepsService(
      state.prisma,
      mkFeed(),
      mkCalc(),
      new FixedClock(NOW),
      mkApprovals(),
    );
    await expect(svc.reorder('stage1', [{ id: 'unknown', orderIndex: 0 }], 'u')).rejects.toThrow(
      InvalidInputError,
    );
  });
});

describe('StepsService: assigneeIds валидация', () => {
  it('только мастера могут быть assignee', async () => {
    const state = mkPrisma();
    setupStage(state, 'stage1', 'p1');
    state.memberships.push({ projectId: 'p1', userId: 'm1', role: 'master' });
    state.memberships.push({ projectId: 'p1', userId: 'f1', role: 'foreman' });
    const svc = new StepsService(
      state.prisma,
      mkFeed(),
      mkCalc(),
      new FixedClock(NOW),
      mkApprovals(),
    );
    // master ok
    await expect(
      svc.create({
        stageId: 'stage1',
        title: 'X',
        assigneeIds: ['m1'],
        actorUserId: 'u',
      }),
    ).resolves.toBeDefined();
    // foreman в assigneeIds — запрет
    await expect(
      svc.create({
        stageId: 'stage1',
        title: 'Y',
        assigneeIds: ['f1'],
        actorUserId: 'u',
      }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('пустой список assigneeIds — ok', async () => {
    const state = mkPrisma();
    setupStage(state, 'stage1', 'p1');
    const svc = new StepsService(
      state.prisma,
      mkFeed(),
      mkCalc(),
      new FixedClock(NOW),
      mkApprovals(),
    );
    await expect(
      svc.create({ stageId: 'stage1', title: 'X', actorUserId: 'u' }),
    ).resolves.toBeDefined();
  });
});
