import { SubstepsService } from './substeps.service';
import { FeedService } from '../feed/feed.service';
import { FixedClock, ForbiddenError, NotFoundError, PrismaService } from '@app/common';

const NOW = new Date('2026-06-10T10:00:00Z');

type SubstepRow = {
  id: string;
  stepId: string;
  text: string;
  authorId: string;
  isDone: boolean;
  doneAt: Date | null;
  doneById: string | null;
};

const mkPrisma = () => {
  const steps = new Map<string, { id: string; stageId: string; projectId: string }>();
  const substeps = new Map<string, SubstepRow>();
  let subSeq = 0;

  const prisma: any = {
    step: {
      findUnique: jest.fn(({ where }: any) => {
        const s = steps.get(where.id);
        if (!s) return null;
        return {
          id: s.id,
          stageId: s.stageId,
          stage: { projectId: s.projectId },
        };
      }),
    },
    substep: {
      findUnique: jest.fn(({ where, include }: any) => {
        const s = substeps.get(where.id);
        if (!s) return null;
        const step = steps.get(s.stepId);
        if (include?.step && step) {
          return {
            ...s,
            step: { stageId: step.stageId, stage: { projectId: step.projectId } },
          };
        }
        return s;
      }),
      create: jest.fn(({ data }: any) => {
        const row: SubstepRow = {
          id: `sub${++subSeq}`,
          stepId: data.stepId,
          text: data.text,
          authorId: data.authorId,
          isDone: false,
          doneAt: null,
          doneById: null,
        };
        substeps.set(row.id, row);
        return row;
      }),
      update: jest.fn(({ where, data }: any) => {
        const s = substeps.get(where.id);
        if (!s) throw new Error('not found');
        for (const [k, v] of Object.entries(data)) (s as any)[k] = v;
        return s;
      }),
      delete: jest.fn(({ where }: any) => {
        substeps.delete(where.id);
      }),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };
  return { prisma: prisma as unknown as PrismaService, steps, substeps };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

describe('SubstepsService.add', () => {
  it('любой участник может добавить подшаг (ТЗ §6.4)', async () => {
    const state = mkPrisma();
    state.steps.set('step1', { id: 'step1', stageId: 'stg1', projectId: 'p1' });
    const feed = mkFeed();
    const svc = new SubstepsService(state.prisma, feed, new FixedClock(NOW));
    const sub = await svc.add('step1', 'проверить уровень', 'master1');
    expect(sub.authorId).toBe('master1');
    expect(feed.emit).toHaveBeenCalledWith(expect.objectContaining({ kind: 'substep_added' }));
  });

  it('404 если step не найден', async () => {
    const state = mkPrisma();
    const svc = new SubstepsService(state.prisma, mkFeed(), new FixedClock(NOW));
    await expect(svc.add('missing', 'x', 'u')).rejects.toThrow(NotFoundError);
  });
});

describe('SubstepsService.update — только автор (ТЗ §6.4)', () => {
  it('автор успешно редактирует свой подшаг', async () => {
    const state = mkPrisma();
    state.steps.set('step1', { id: 'step1', stageId: 'stg1', projectId: 'p1' });
    const svc = new SubstepsService(state.prisma, mkFeed(), new FixedClock(NOW));
    const sub = await svc.add('step1', 'первая версия', 'master1');
    const updated = await svc.update(sub.id, 'обновлённая версия', 'master1');
    expect(updated.text).toBe('обновлённая версия');
  });

  it('не автор — 403 ForbiddenError', async () => {
    const state = mkPrisma();
    state.steps.set('step1', { id: 'step1', stageId: 'stg1', projectId: 'p1' });
    const svc = new SubstepsService(state.prisma, mkFeed(), new FixedClock(NOW));
    const sub = await svc.add('step1', 'первая', 'master1');
    await expect(svc.update(sub.id, 'взломать', 'master2')).rejects.toThrow(ForbiddenError);
  });
});

describe('SubstepsService.complete — любой участник (чек-лист, ТЗ §6.4)', () => {
  it('мастер может отметить чужой подшаг как выполненный', async () => {
    const state = mkPrisma();
    state.steps.set('step1', { id: 'step1', stageId: 'stg1', projectId: 'p1' });
    const clock = new FixedClock(NOW);
    const svc = new SubstepsService(state.prisma, mkFeed(), clock);
    const sub = await svc.add('step1', 'любой подшаг', 'foreman1');
    const done = await svc.complete(sub.id, 'master2');
    expect(done.isDone).toBe(true);
    expect(done.doneAt).toEqual(NOW);
    expect(done.doneById).toBe('master2');
  });

  it('uncomplete снимает галочку', async () => {
    const state = mkPrisma();
    state.steps.set('step1', { id: 'step1', stageId: 'stg1', projectId: 'p1' });
    const svc = new SubstepsService(state.prisma, mkFeed(), new FixedClock(NOW));
    const sub = await svc.add('step1', 'x', 'u1');
    await svc.complete(sub.id, 'u2');
    const un = await svc.uncomplete(sub.id, 'u2');
    expect(un.isDone).toBe(false);
    expect(un.doneAt).toBeNull();
  });
});

describe('SubstepsService.delete — только автор', () => {
  it('автор может удалить', async () => {
    const state = mkPrisma();
    state.steps.set('step1', { id: 'step1', stageId: 'stg1', projectId: 'p1' });
    const svc = new SubstepsService(state.prisma, mkFeed(), new FixedClock(NOW));
    const sub = await svc.add('step1', 'x', 'u1');
    await svc.delete(sub.id, 'u1');
    expect(state.substeps.size).toBe(0);
  });

  it('не автор — 403', async () => {
    const state = mkPrisma();
    state.steps.set('step1', { id: 'step1', stageId: 'stg1', projectId: 'p1' });
    const svc = new SubstepsService(state.prisma, mkFeed(), new FixedClock(NOW));
    const sub = await svc.add('step1', 'x', 'u1');
    await expect(svc.delete(sub.id, 'u2')).rejects.toThrow(ForbiddenError);
  });
});
