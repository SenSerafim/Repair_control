import { QuestionsService } from './questions.service';
import { FeedService } from '../feed/feed.service';
import {
  ConflictError,
  FixedClock,
  ForbiddenError,
  NotFoundError,
  PrismaService,
} from '@app/common';

const NOW = new Date('2026-06-10T12:00:00Z');

type QuestionRow = {
  id: string;
  stepId: string;
  authorId: string;
  addresseeId: string;
  text: string;
  status: 'open' | 'answered' | 'closed';
  answer: string | null;
  answeredAt: Date | null;
  answeredBy: string | null;
};

const mkPrisma = () => {
  const steps = new Map<string, { id: string; stageId: string; projectId: string }>();
  const questions = new Map<string, QuestionRow>();
  let seq = 0;

  const prisma: any = {
    step: {
      findUnique: jest.fn(({ where }: any) => {
        const s = steps.get(where.id);
        if (!s) return null;
        return { id: s.id, stageId: s.stageId, stage: { projectId: s.projectId } };
      }),
    },
    question: {
      findUnique: jest.fn(({ where, include }: any) => {
        const q = questions.get(where.id);
        if (!q) return null;
        if (include?.step) {
          const step = steps.get(q.stepId);
          return {
            ...q,
            step: { stageId: step!.stageId, stage: { projectId: step!.projectId } },
          };
        }
        return q;
      }),
      create: jest.fn(({ data }: any) => {
        const q: QuestionRow = {
          id: `q${++seq}`,
          stepId: data.stepId,
          authorId: data.authorId,
          addresseeId: data.addresseeId,
          text: data.text,
          status: 'open',
          answer: null,
          answeredAt: null,
          answeredBy: null,
        };
        questions.set(q.id, q);
        return q;
      }),
      update: jest.fn(({ where, data }: any) => {
        const q = questions.get(where.id);
        if (!q) throw new Error('not found');
        Object.assign(q, data);
        return q;
      }),
      findMany: jest.fn(({ where }: any) => {
        return [...questions.values()].filter((q) => {
          if (where.stepId && q.stepId !== where.stepId) return false;
          if (where.status && q.status !== where.status) return false;
          if (where.authorId && q.authorId !== where.authorId) return false;
          if (where.addresseeId && q.addresseeId !== where.addresseeId) return false;
          if (where.OR) {
            const ok = where.OR.some((c: any) => {
              if (c.authorId) return q.authorId === c.authorId;
              if (c.addresseeId) return q.addresseeId === c.addresseeId;
              return false;
            });
            if (!ok) return false;
          }
          return true;
        });
      }),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };
  return { prisma: prisma as unknown as PrismaService, steps, questions };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

describe('QuestionsService.ask', () => {
  it('создаёт вопрос статусом open и эмитит question_asked', async () => {
    const state = mkPrisma();
    state.steps.set('step1', { id: 'step1', stageId: 's1', projectId: 'p1' });
    const feed = mkFeed();
    const svc = new QuestionsService(state.prisma, feed, new FixedClock(NOW));
    const q = await svc.ask('step1', 'foreman1', 'Какой тип плитки?', 'master1');
    expect(q.status).toBe('open');
    expect(q.authorId).toBe('master1');
    expect(q.addresseeId).toBe('foreman1');
    expect(feed.emit).toHaveBeenCalledWith(expect.objectContaining({ kind: 'question_asked' }));
  });

  it('step не найден → 404', async () => {
    const state = mkPrisma();
    const svc = new QuestionsService(state.prisma, mkFeed(), new FixedClock(NOW));
    await expect(svc.ask('missing', 'f1', 'text', 'm1')).rejects.toThrow(NotFoundError);
  });
});

describe('QuestionsService.answer — только addressee', () => {
  it('addressee может ответить → статус answered, answeredAt=clock.now()', async () => {
    const state = mkPrisma();
    state.steps.set('step1', { id: 'step1', stageId: 's1', projectId: 'p1' });
    const clock = new FixedClock(NOW);
    const svc = new QuestionsService(state.prisma, mkFeed(), clock);
    const q = await svc.ask('step1', 'f1', 'вопрос', 'm1');
    const answered = await svc.answer(q.id, 'ответ', 'f1');
    expect(answered.status).toBe('answered');
    expect(answered.answer).toBe('ответ');
    expect(answered.answeredAt).toEqual(NOW);
    expect(answered.answeredBy).toBe('f1');
  });

  it('не addressee — 403 ForbiddenError', async () => {
    const state = mkPrisma();
    state.steps.set('step1', { id: 'step1', stageId: 's1', projectId: 'p1' });
    const svc = new QuestionsService(state.prisma, mkFeed(), new FixedClock(NOW));
    const q = await svc.ask('step1', 'f1', 'вопрос', 'm1');
    await expect(svc.answer(q.id, 'взлом', 'stranger')).rejects.toThrow(ForbiddenError);
  });

  it('уже answered → Conflict', async () => {
    const state = mkPrisma();
    state.steps.set('step1', { id: 'step1', stageId: 's1', projectId: 'p1' });
    const svc = new QuestionsService(state.prisma, mkFeed(), new FixedClock(NOW));
    const q = await svc.ask('step1', 'f1', 'x', 'm1');
    await svc.answer(q.id, 'y', 'f1');
    await expect(svc.answer(q.id, 'второй ответ', 'f1')).rejects.toThrow(ConflictError);
  });

  it('уже closed → Conflict', async () => {
    const state = mkPrisma();
    state.steps.set('step1', { id: 'step1', stageId: 's1', projectId: 'p1' });
    const svc = new QuestionsService(state.prisma, mkFeed(), new FixedClock(NOW));
    const q = await svc.ask('step1', 'f1', 'x', 'm1');
    await svc.close(q.id, 'm1');
    await expect(svc.answer(q.id, 'y', 'f1')).rejects.toThrow(ConflictError);
  });
});

describe('QuestionsService.close — только автор', () => {
  it('автор может закрыть', async () => {
    const state = mkPrisma();
    state.steps.set('step1', { id: 'step1', stageId: 's1', projectId: 'p1' });
    const svc = new QuestionsService(state.prisma, mkFeed(), new FixedClock(NOW));
    const q = await svc.ask('step1', 'f1', 'x', 'm1');
    const closed = await svc.close(q.id, 'm1');
    expect(closed.status).toBe('closed');
  });

  it('не автор — 403', async () => {
    const state = mkPrisma();
    state.steps.set('step1', { id: 'step1', stageId: 's1', projectId: 'p1' });
    const svc = new QuestionsService(state.prisma, mkFeed(), new FixedClock(NOW));
    const q = await svc.ask('step1', 'f1', 'x', 'm1');
    await expect(svc.close(q.id, 'f1')).rejects.toThrow(ForbiddenError);
  });
});

describe('QuestionsService.listForUser', () => {
  it('filter=inbox возвращает вопросы где addressee=userId', async () => {
    const state = mkPrisma();
    state.steps.set('step1', { id: 'step1', stageId: 's1', projectId: 'p1' });
    const svc = new QuestionsService(state.prisma, mkFeed(), new FixedClock(NOW));
    await svc.ask('step1', 'u1', 'q1', 'u2');
    await svc.ask('step1', 'u2', 'q2', 'u1');
    const inbox = await svc.listForUser('u1', 'inbox');
    expect(inbox).toHaveLength(1);
    expect(inbox[0].text).toBe('q1');
  });

  it('filter=sent возвращает авторские', async () => {
    const state = mkPrisma();
    state.steps.set('step1', { id: 'step1', stageId: 's1', projectId: 'p1' });
    const svc = new QuestionsService(state.prisma, mkFeed(), new FixedClock(NOW));
    await svc.ask('step1', 'u1', 'q1', 'u2');
    await svc.ask('step1', 'u2', 'q2', 'u1');
    const sent = await svc.listForUser('u1', 'sent');
    expect(sent).toHaveLength(1);
    expect(sent[0].text).toBe('q2');
  });
});
