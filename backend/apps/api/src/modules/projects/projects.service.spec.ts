import { ProjectsService } from './projects.service';
import { FeedService } from '../feed/feed.service';
import {
  ConflictError,
  FixedClock,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';

const NOW = new Date('2026-06-01T00:00:00Z');

const mkPrisma = () => {
  const projects = new Map<string, any>();
  const stages: any[] = [];
  let id = 0;
  const prisma: any = {
    project: {
      create: jest.fn(({ data }: any) => {
        const p = {
          id: `p${++id}`,
          status: 'active',
          workBudget: BigInt(data.workBudget ?? 0),
          materialsBudget: BigInt(data.materialsBudget ?? 0),
          archivedAt: null,
          ...data,
        };
        projects.set(p.id, p);
        return p;
      }),
      findUnique: jest.fn(({ where, include }: any) => {
        const p = projects.get(where.id);
        if (!p) return null;
        return include?.stages ? { ...p, stages: stages.filter((s) => s.projectId === p.id) } : p;
      }),
      findMany: jest.fn(({ where }: any) => {
        const all = [...projects.values()];
        return all.filter((p) => {
          if (where.status && p.status !== where.status) return false;
          if (where.OR) {
            return where.OR.some((c: any) => c.ownerId === p.ownerId);
          }
          return true;
        });
      }),
      update: jest.fn(({ where, data }: any) => {
        const p = projects.get(where.id);
        Object.assign(p, data);
        return p;
      }),
    },
    stage: {
      create: jest.fn(({ data }: any) => {
        const s = { id: `s${stages.length + 1}`, ...data };
        stages.push(s);
        return s;
      }),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };
  return { prisma: prisma as unknown as PrismaService, projects, stages };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

describe('ProjectsService.create', () => {
  it('создаёт проект, добавляет owner-membership (косвенно через prisma.create), пишет событие в ленту', async () => {
    const { prisma, projects } = mkPrisma();
    const feed = mkFeed();
    const svc = new ProjectsService(prisma, feed, new FixedClock(NOW));
    const p = await svc.create({
      ownerId: 'u-owner',
      title: 'Квартира',
      workBudget: 1_000_000,
      materialsBudget: 500_000,
    });
    expect(p.title).toBe('Квартира');
    expect(p.workBudget).toBe(1_000_000);
    expect(feed.emit).toHaveBeenCalledWith(expect.objectContaining({ kind: 'project_created' }));
    expect(projects.size).toBe(1);
  });

  it('validates plannedStart <= plannedEnd', async () => {
    const { prisma } = mkPrisma();
    const svc = new ProjectsService(prisma, mkFeed(), new FixedClock(NOW));
    await expect(
      svc.create({
        ownerId: 'u',
        title: 't',
        plannedStart: '2026-06-10',
        plannedEnd: '2026-06-01',
      }),
    ).rejects.toThrow(InvalidInputError);
  });
});

describe('ProjectsService.archive/restore', () => {
  it('archive помечает status=archived и пишет в ленту', async () => {
    const { prisma } = mkPrisma();
    const feed = mkFeed();
    const svc = new ProjectsService(prisma, feed, new FixedClock(NOW));
    const p = await svc.create({ ownerId: 'u', title: 'T' });
    const archived = await svc.archive(p.id, 'u');
    expect(archived.status).toBe('archived');
    expect(feed.emit).toHaveBeenCalledWith(expect.objectContaining({ kind: 'project_archived' }));
  });

  it('restore возвращает active', async () => {
    const { prisma } = mkPrisma();
    const svc = new ProjectsService(prisma, mkFeed(), new FixedClock(NOW));
    const p = await svc.create({ ownerId: 'u', title: 'T' });
    await svc.archive(p.id, 'u');
    const restored = await svc.restore(p.id, 'u');
    expect(restored.status).toBe('active');
  });

  it('update на архивном проекте → 409', async () => {
    const { prisma } = mkPrisma();
    const svc = new ProjectsService(prisma, mkFeed(), new FixedClock(NOW));
    const p = await svc.create({ ownerId: 'u', title: 'T' });
    await svc.archive(p.id, 'u');
    await expect(svc.update(p.id, { title: 'New' }, 'u')).rejects.toThrow(ConflictError);
  });

  it('archive → 404 для несуществующего', async () => {
    const { prisma } = mkPrisma();
    const svc = new ProjectsService(prisma, mkFeed(), new FixedClock(NOW));
    await expect(svc.archive('p-missing', 'u')).rejects.toThrow(NotFoundError);
  });
});

describe('ProjectsService.copy — ТЗ §4.3', () => {
  it('копирует название (с суффиксом), этапы и плановые бюджеты; не копирует прогресс', async () => {
    const { prisma, projects, stages } = mkPrisma();
    const svc = new ProjectsService(prisma, mkFeed(), new FixedClock(NOW));
    const src = await svc.create({
      ownerId: 'u',
      title: 'Оригинал',
      workBudget: 100_000,
    });
    // подсаживаем этапы в исходник напрямую через мок
    stages.push({
      projectId: src.id,
      title: 'Электрика',
      orderIndex: 0,
      plannedEnd: new Date('2026-07-01'),
      workBudget: BigInt(0),
      materialsBudget: BigInt(0),
    });

    const copy = await svc.copy(src.id, 'u');
    expect(copy.title).toContain('Оригинал');
    expect(copy.title).toContain('(копия)');
    expect(copy.workBudget).toBe(100_000);
    expect(projects.size).toBe(2);
    // 1 этап в исходнике + 1 этап-копия в копии
    expect(stages.filter((s) => s.projectId === copy.id).length).toBe(1);
  });

  it('можно задать новое название при копировании', async () => {
    const { prisma } = mkPrisma();
    const svc = new ProjectsService(prisma, mkFeed(), new FixedClock(NOW));
    const src = await svc.create({ ownerId: 'u', title: 'Оригинал' });
    const copy = await svc.copy(src.id, 'u', 'Кастомная копия');
    expect(copy.title).toBe('Кастомная копия');
  });
});
