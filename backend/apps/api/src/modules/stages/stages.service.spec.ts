import { StagesService } from './stages.service';
import { StageLifecycle } from './stage-lifecycle';
import { ProgressCalculator } from './progress-calculator';
import { FeedService } from '../feed/feed.service';
import {
  ConflictError,
  FixedClock,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';

const NOW = new Date('2026-06-01T10:00:00Z');

const mkPrisma = () => {
  const stages = new Map<string, any>();
  const projects = new Map<string, any>();
  const pauses: any[] = [];
  let stageSeq = 0;
  let pauseSeq = 0;
  const prisma: any = {
    stage: {
      findUnique: jest.fn(({ where }: any) => stages.get(where.id) ?? null),
      findMany: jest.fn(({ where }: any) =>
        [...stages.values()].filter((s) => s.projectId === where.projectId),
      ),
      count: jest.fn(
        ({ where }: any) =>
          [...stages.values()].filter((s) => s.projectId === where.projectId).length,
      ),
      create: jest.fn(({ data }: any) => {
        const s = {
          id: `s${++stageSeq}`,
          status: 'pending',
          pauseDurationMs: BigInt(0),
          progressCache: 0,
          startedAt: null,
          sentToReviewAt: null,
          doneAt: null,
          workBudget: BigInt(data.workBudget ?? 0),
          materialsBudget: BigInt(data.materialsBudget ?? 0),
          foremanIds: data.foremanIds ?? [],
          ...data,
        };
        stages.set(s.id, s);
        return s;
      }),
      update: jest.fn(({ where, data }: any) => {
        const s = stages.get(where.id);
        for (const [k, v] of Object.entries(data)) {
          (s as any)[k] = v;
        }
        return s;
      }),
    },
    project: {
      findUnique: jest.fn(({ where }: any) => projects.get(where.id) ?? null),
      update: jest.fn(),
    },
    pause: {
      create: jest.fn(({ data }: any) => {
        const p = { id: `ps${++pauseSeq}`, startedAt: new Date(NOW), endedAt: null, ...data };
        pauses.push(p);
        return p;
      }),
      findFirst: jest.fn(({ where }: any) => {
        const list = pauses.filter(
          (p) =>
            p.stageId === where.stageId && (where.endedAt === null ? p.endedAt === null : true),
        );
        return list[list.length - 1] ?? null;
      }),
      update: jest.fn(({ where, data }: any) => {
        const p = pauses.find((x) => x.id === where.id);
        Object.assign(p, data);
        return p;
      }),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };
  return { prisma: prisma as unknown as PrismaService, stages, projects, pauses };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

const mkCalc = (): ProgressCalculator =>
  ({
    stageSemaphore: jest.fn(),
    recalcStage: jest.fn().mockResolvedValue(undefined),
    recalcProject: jest.fn().mockResolvedValue(undefined),
    computeProjectProgress: jest.fn(),
    computeProjectSemaphore: jest.fn(),
  }) as any;

describe('StagesService.create', () => {
  it('создаёт этап и записывает в ленту', async () => {
    const { prisma, projects, stages } = mkPrisma();
    projects.set('p1', { id: 'p1', status: 'active', plannedEnd: new Date('2026-12-31') });
    const clock = new FixedClock(NOW);
    const svc = new StagesService(prisma, mkFeed(), new StageLifecycle(), mkCalc(), clock);
    const s = await svc.create({
      projectId: 'p1',
      title: 'Демонтаж',
      plannedStart: '2026-06-10',
      plannedEnd: '2026-06-20',
      actorUserId: 'u1',
    });
    expect(s.title).toBe('Демонтаж');
    expect(stages.size).toBe(1);
  });

  it('отклоняет создание этапа в архивном проекте', async () => {
    const { prisma, projects } = mkPrisma();
    projects.set('p1', { id: 'p1', status: 'archived' });
    const clock = new FixedClock(NOW);
    const svc = new StagesService(prisma, mkFeed(), new StageLifecycle(), mkCalc(), clock);
    await expect(svc.create({ projectId: 'p1', title: 'X', actorUserId: 'u1' })).rejects.toThrow(
      ConflictError,
    );
  });

  it('не найден проект → 404', async () => {
    const { prisma } = mkPrisma();
    const clock = new FixedClock(NOW);
    const svc = new StagesService(prisma, mkFeed(), new StageLifecycle(), mkCalc(), clock);
    await expect(
      svc.create({ projectId: 'p-missing', title: 'X', actorUserId: 'u1' }),
    ).rejects.toThrow(NotFoundError);
  });

  it('если этап выходит за рамки проекта — пишет предупреждение в ленту', async () => {
    const { prisma, projects } = mkPrisma();
    projects.set('p1', {
      id: 'p1',
      status: 'active',
      plannedEnd: new Date('2026-06-15'),
    });
    const feed = mkFeed();
    const clock = new FixedClock(NOW);
    const svc = new StagesService(prisma, feed, new StageLifecycle(), mkCalc(), clock);
    await svc.create({
      projectId: 'p1',
      title: 'X',
      plannedEnd: '2026-07-10', // позже окончания проекта
      actorUserId: 'u1',
    });
    expect(feed.emit).toHaveBeenCalledWith(
      expect.objectContaining({ kind: 'stage_deadline_exceeds_project' }),
    );
  });
});

describe('StagesService lifecycle + deadline recalculation', () => {
  it('start переводит pending → active и фиксирует startedAt', async () => {
    const { prisma, projects, stages } = mkPrisma();
    projects.set('p1', { id: 'p1', status: 'active' });
    const clock = new FixedClock(NOW);
    const svc = new StagesService(prisma, mkFeed(), new StageLifecycle(), mkCalc(), clock);
    const s = await svc.create({ projectId: 'p1', title: 'X', actorUserId: 'u' });
    await svc.start(s.id, 'u');
    const fresh = stages.get(s.id);
    expect(fresh.status).toBe('active');
    expect(fresh.startedAt).toEqual(NOW);
  });

  it('pause требует reason → создаёт Pause и переводит в paused', async () => {
    const { prisma, projects, stages, pauses } = mkPrisma();
    projects.set('p1', { id: 'p1', status: 'active' });
    const clock = new FixedClock(NOW);
    const svc = new StagesService(prisma, mkFeed(), new StageLifecycle(), mkCalc(), clock);
    const s = await svc.create({ projectId: 'p1', title: 'X', actorUserId: 'u' });
    await svc.start(s.id, 'u');
    await svc.pause(s.id, 'u', 'materials', 'ждём плитку');
    const fresh = stages.get(s.id);
    expect(fresh.status).toBe('paused');
    expect(pauses[0]).toMatchObject({ reason: 'materials', comment: 'ждём плитку' });
  });

  it('resume пересчитывает дедлайн: originalEnd + накопленные паузы (ТЗ §4.2)', async () => {
    const { prisma, projects, stages } = mkPrisma();
    projects.set('p1', { id: 'p1', status: 'active' });
    const clock = new FixedClock(NOW);
    const svc = new StagesService(prisma, mkFeed(), new StageLifecycle(), mkCalc(), clock);
    const s = await svc.create({
      projectId: 'p1',
      title: 'X',
      plannedStart: '2026-05-01',
      plannedEnd: '2026-06-20',
      actorUserId: 'u',
    });
    await svc.start(s.id, 'u');

    // Пауза на 2 дня
    clock.set(new Date('2026-06-01T10:00:00Z'));
    await svc.pause(s.id, 'u', 'force_majeure');
    clock.set(new Date('2026-06-03T10:00:00Z'));
    await svc.resume(s.id, 'u');

    const fresh = stages.get(s.id);
    const original = new Date('2026-06-20').getTime();
    const twoDaysMs = 2 * 24 * 60 * 60 * 1000;
    // дедлайн сдвинут на 2 дня вперёд
    expect(new Date(fresh.plannedEnd).getTime()).toBeGreaterThanOrEqual(
      original + twoDaysMs - 1000,
    );
    expect(Number(fresh.pauseDurationMs)).toBeGreaterThanOrEqual(twoDaysMs - 1000);
  });

  it('send-to-review переводит active → review и фиксирует sentToReviewAt', async () => {
    const { prisma, projects, stages } = mkPrisma();
    projects.set('p1', { id: 'p1', status: 'active' });
    const clock = new FixedClock(NOW);
    const svc = new StagesService(prisma, mkFeed(), new StageLifecycle(), mkCalc(), clock);
    const s = await svc.create({ projectId: 'p1', title: 'X', actorUserId: 'u' });
    await svc.start(s.id, 'u');
    await svc.sendToReview(s.id, 'u');
    const fresh = stages.get(s.id);
    expect(fresh.status).toBe('review');
    expect(fresh.sentToReviewAt).toEqual(NOW);
  });

  it('невалидный переход (pause на pending) → InvalidInputError', async () => {
    const { prisma, projects } = mkPrisma();
    projects.set('p1', { id: 'p1', status: 'active' });
    const clock = new FixedClock(NOW);
    const svc = new StagesService(prisma, mkFeed(), new StageLifecycle(), mkCalc(), clock);
    const s = await svc.create({ projectId: 'p1', title: 'X', actorUserId: 'u' });
    await expect(svc.pause(s.id, 'u', 'materials')).rejects.toThrow(InvalidInputError);
  });
});

describe('StagesService.reorder', () => {
  it('переписывает orderIndex по массиву', async () => {
    const { prisma, projects, stages } = mkPrisma();
    projects.set('p1', { id: 'p1', status: 'active' });
    const clock = new FixedClock(NOW);
    const svc = new StagesService(prisma, mkFeed(), new StageLifecycle(), mkCalc(), clock);
    const a = await svc.create({ projectId: 'p1', title: 'A', actorUserId: 'u' });
    const b = await svc.create({ projectId: 'p1', title: 'B', actorUserId: 'u' });
    await svc.reorder(
      'p1',
      [
        { id: a.id, orderIndex: 1 },
        { id: b.id, orderIndex: 0 },
      ],
      'u',
    );
    expect(stages.get(a.id).orderIndex).toBe(1);
    expect(stages.get(b.id).orderIndex).toBe(0);
  });

  it('неизвестный stage id → InvalidInputError', async () => {
    const { prisma, projects } = mkPrisma();
    projects.set('p1', { id: 'p1', status: 'active' });
    const clock = new FixedClock(NOW);
    const svc = new StagesService(prisma, mkFeed(), new StageLifecycle(), mkCalc(), clock);
    await expect(svc.reorder('p1', [{ id: 's-unknown', orderIndex: 0 }], 'u')).rejects.toThrow(
      InvalidInputError,
    );
  });
});
