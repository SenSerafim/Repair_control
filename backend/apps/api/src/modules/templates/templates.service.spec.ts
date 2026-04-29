import { TemplatesService } from './templates.service';
import { FeedService } from '../feed/feed.service';
import { NotFoundError, PrismaService } from '@app/common';

/**
 * Покрытие багов §A.1 + A.2 из плана редизайна Кластера C:
 *  - applyToProject должен копировать tpl.steps → Step (раньше создавал пустой этап)
 *  - createFromStage должен копировать stage.steps → TemplateStep (раньше создавал пустой шаблон)
 *
 * Тесты — на in-memory mock prisma по образцу stages.service.spec.ts.
 */
const mkPrisma = () => {
  const templates = new Map<string, any>();
  const templateSteps: any[] = [];
  const stages = new Map<string, any>();
  const steps: any[] = [];
  let templateSeq = 0;
  let templateStepSeq = 0;
  let stageSeq = 0;
  let stepSeq = 0;

  const prisma: any = {
    template: {
      findMany: jest.fn(({ where, include }: any) => {
        const list = [...templates.values()].filter((t) => {
          if (where?.kind && t.kind !== where.kind) return false;
          if (where?.authorId && t.authorId !== where.authorId) return false;
          return true;
        });
        if (include?.steps) {
          return list.map((t) => ({
            ...t,
            steps: templateSteps
              .filter((s) => s.templateId === t.id)
              .sort((a, b) => a.orderIndex - b.orderIndex),
          }));
        }
        return list;
      }),
      findUnique: jest.fn(({ where, include }: any) => {
        const t = templates.get(where.id);
        if (!t) return null;
        if (include?.steps) {
          return {
            ...t,
            steps: templateSteps
              .filter((s) => s.templateId === t.id)
              .sort((a, b) => a.orderIndex - b.orderIndex),
          };
        }
        return t;
      }),
      create: jest.fn(({ data }: any) => {
        const t = { id: `t${++templateSeq}`, ...data };
        templates.set(t.id, t);
        return t;
      }),
    },
    templateStep: {
      createMany: jest.fn(({ data }: any) => {
        for (const row of data) {
          templateSteps.push({ id: `ts${++templateStepSeq}`, ...row });
        }
        return { count: data.length };
      }),
    },
    stage: {
      findUnique: jest.fn(({ where, include }: any) => {
        const s = stages.get(where.id);
        if (!s) return null;
        if (include?.steps) {
          return {
            ...s,
            steps: steps
              .filter((st) => st.stageId === s.id)
              .sort((a, b) => a.orderIndex - b.orderIndex),
          };
        }
        return s;
      }),
      count: jest.fn(
        ({ where }: any) =>
          [...stages.values()].filter((s) => s.projectId === where.projectId).length,
      ),
      create: jest.fn(({ data }: any) => {
        const s = { id: `s${++stageSeq}`, ...data };
        stages.set(s.id, s);
        return s;
      }),
    },
    step: {
      createMany: jest.fn(({ data }: any) => {
        for (const row of data) {
          steps.push({ id: `st${++stepSeq}`, type: 'regular', status: 'pending', ...row });
        }
        return { count: data.length };
      }),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };

  return {
    prisma: prisma as unknown as PrismaService,
    templates,
    templateSteps,
    stages,
    steps,
  };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

describe('TemplatesService.applyToProject (A.1: копирует шаги шаблона)', () => {
  it('создаёт этап и Step-ы из tpl.steps в правильном порядке', async () => {
    const { prisma, templates, templateSteps, steps } = mkPrisma();
    templates.set('t1', { id: 't1', kind: 'platform', title: 'Электрика' });
    templateSteps.push(
      { id: 'ts1', templateId: 't1', title: 'Штробление', orderIndex: 0, price: null },
      { id: 'ts2', templateId: 't1', title: 'Прокладка кабелей', orderIndex: 1, price: null },
      { id: 'ts3', templateId: 't1', title: 'Установка розеток', orderIndex: 2, price: null },
    );
    const svc = new TemplatesService(prisma, mkFeed());
    const stage = await svc.applyToProject({
      templateId: 't1',
      projectId: 'p1',
      actorUserId: 'u1',
    });
    expect(stage).not.toBeNull();
    const created = steps.filter((s) => s.stageId === stage!.id);
    expect(created).toHaveLength(3);
    expect(created.map((s) => s.title)).toEqual([
      'Штробление',
      'Прокладка кабелей',
      'Установка розеток',
    ]);
    expect(created.map((s) => s.orderIndex)).toEqual([0, 1, 2]);
    expect(created.every((s) => s.stageId === stage!.id)).toBe(true);
  });

  it('эмитит feed-событие с stepCount', async () => {
    const { prisma, templates, templateSteps } = mkPrisma();
    templates.set('t1', { id: 't1', kind: 'platform', title: 'Демонтаж' });
    templateSteps.push({ id: 'ts1', templateId: 't1', title: 'A', orderIndex: 0 });
    templateSteps.push({ id: 'ts2', templateId: 't1', title: 'B', orderIndex: 1 });
    const feed = mkFeed();
    const svc = new TemplatesService(prisma, feed);
    await svc.applyToProject({ templateId: 't1', projectId: 'p1', actorUserId: 'u1' });
    expect(feed.emit).toHaveBeenCalledWith(
      expect.objectContaining({
        kind: 'stage_created',
        payload: expect.objectContaining({ fromTemplateId: 't1', stepCount: 2 }),
      }),
    );
  });

  it('пустой шаблон → этап без шагов, без падения', async () => {
    const { prisma, templates, steps } = mkPrisma();
    templates.set('t1', { id: 't1', kind: 'platform', title: 'X' });
    const svc = new TemplatesService(prisma, mkFeed());
    const stage = await svc.applyToProject({
      templateId: 't1',
      projectId: 'p1',
      actorUserId: 'u1',
    });
    expect(stage).not.toBeNull();
    expect(steps.filter((s) => s.stageId === stage!.id)).toHaveLength(0);
  });

  it('шаблона нет → NotFoundError', async () => {
    const { prisma } = mkPrisma();
    const svc = new TemplatesService(prisma, mkFeed());
    await expect(
      svc.applyToProject({ templateId: 'missing', projectId: 'p1', actorUserId: 'u1' }),
    ).rejects.toThrow(NotFoundError);
  });
});

describe('TemplatesService.createFromStage (A.2: копирует шаги этапа)', () => {
  it('копирует stage.steps в TemplateStep в правильном порядке', async () => {
    const { prisma, stages, steps, templateSteps } = mkPrisma();
    stages.set('s1', { id: 's1', projectId: 'p1', title: 'My Stage' });
    steps.push(
      { id: 'st1', stageId: 's1', title: 'Замер', orderIndex: 0, type: 'regular', price: null },
      { id: 'st2', stageId: 's1', title: 'Закупка', orderIndex: 1, type: 'regular', price: null },
      { id: 'st3', stageId: 's1', title: 'Монтаж', orderIndex: 2, type: 'regular', price: null },
    );
    const svc = new TemplatesService(prisma, mkFeed());
    const tpl = await svc.createFromStage({ stageId: 's1', authorId: 'u1', title: 'My Tpl' });
    expect(tpl).not.toBeNull();
    const copied = templateSteps.filter((ts) => ts.templateId === tpl!.id);
    expect(copied).toHaveLength(3);
    expect(copied.map((ts) => ts.title)).toEqual(['Замер', 'Закупка', 'Монтаж']);
    expect(copied.map((ts) => ts.orderIndex)).toEqual([0, 1, 2]);
  });

  it('extra-шаги не попадают как oплачиваемые в TemplateStep (price=null)', async () => {
    const { prisma, stages, steps, templateSteps } = mkPrisma();
    stages.set('s1', { id: 's1', projectId: 'p1', title: 'X' });
    steps.push(
      { id: 'st1', stageId: 's1', title: 'extra', orderIndex: 0, type: 'extra', price: 5000n },
      { id: 'st2', stageId: 's1', title: 'reg-paid', orderIndex: 1, type: 'regular', price: 200n },
      { id: 'st3', stageId: 's1', title: 'reg-free', orderIndex: 2, type: 'regular', price: null },
    );
    const svc = new TemplatesService(prisma, mkFeed());
    const tpl = await svc.createFromStage({ stageId: 's1', authorId: 'u1', title: 'T' });
    const copied = templateSteps.filter((ts) => ts.templateId === tpl!.id);
    // extra → price отбрасываем
    expect(copied.find((c) => c.title === 'extra')!.price).toBeNull();
    // regular с ценой → копируется
    expect(copied.find((c) => c.title === 'reg-paid')!.price).toBe(200n);
    // regular без цены → null
    expect(copied.find((c) => c.title === 'reg-free')!.price).toBeNull();
  });

  it('этап без шагов → шаблон без шагов, без падения', async () => {
    const { prisma, stages, templateSteps } = mkPrisma();
    stages.set('s1', { id: 's1', projectId: 'p1', title: 'Empty' });
    const svc = new TemplatesService(prisma, mkFeed());
    const tpl = await svc.createFromStage({ stageId: 's1', authorId: 'u1', title: 'T' });
    expect(tpl).not.toBeNull();
    expect(templateSteps.filter((ts) => ts.templateId === tpl!.id)).toHaveLength(0);
  });

  it('этапа нет → NotFoundError', async () => {
    const { prisma } = mkPrisma();
    const svc = new TemplatesService(prisma, mkFeed());
    await expect(
      svc.createFromStage({ stageId: 'missing', authorId: 'u1', title: 'T' }),
    ).rejects.toThrow(NotFoundError);
  });
});
