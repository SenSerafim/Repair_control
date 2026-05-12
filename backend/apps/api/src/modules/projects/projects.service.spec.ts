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
  const memberships: any[] = [];
  const invitations: any[] = [];
  let id = 0;
  let mId = 0;
  let invId = 0;
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
        const s = { id: `s${stages.length + 1}`, foremanIds: [], ...data };
        stages.push(s);
        return s;
      }),
    },
    membership: {
      findMany: jest.fn(({ where }: any) =>
        memberships.filter(
          (m) =>
            (!where?.projectId || m.projectId === where.projectId) &&
            (where?.removedAt === undefined || m.removedAt === where.removedAt),
        ),
      ),
      create: jest.fn(({ data }: any) => {
        const m = {
          id: `m${++mId}`,
          stageIds: [],
          permissions: {},
          removedAt: null,
          ...data,
        };
        memberships.push(m);
        return m;
      }),
      updateMany: jest.fn(({ where, data }: any) => {
        let updated = 0;
        for (const m of memberships) {
          if (
            (!where.projectId || m.projectId === where.projectId) &&
            (!where.userId || m.userId === where.userId)
          ) {
            Object.assign(m, data);
            updated++;
          }
        }
        return { count: updated };
      }),
    },
    projectInvitation: {
      findMany: jest.fn(({ where }: any) =>
        invitations.filter(
          (i) =>
            (!where?.projectId || i.projectId === where.projectId) &&
            (!where?.status || i.status === where.status),
        ),
      ),
      create: jest.fn(({ data }: any) => {
        const inv = { id: `inv${++invId}`, stageIds: [], ...data };
        invitations.push(inv);
        return inv;
      }),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };
  return {
    prisma: prisma as unknown as PrismaService,
    projects,
    stages,
    memberships,
    invitations,
  };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

const mkChats = () =>
  ({
    ensureProjectChat: jest.fn().mockResolvedValue({ id: 'chat-mock' }),
  }) as any;

const mkCalculator = () =>
  ({
    recalcProject: jest.fn().mockResolvedValue(undefined),
    recalcStage: jest.fn().mockResolvedValue(undefined),
    stageSemaphore: jest.fn(),
    computeProjectProgress: jest.fn(),
    computeProjectSemaphore: jest.fn(),
  }) as any;

describe('ProjectsService.create', () => {
  it('создаёт проект, добавляет owner-membership (косвенно через prisma.create), пишет событие в ленту', async () => {
    const { prisma, projects } = mkPrisma();
    const feed = mkFeed();
    const svc = new ProjectsService(prisma, feed, new FixedClock(NOW), mkChats(), mkCalculator());
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

  it('по умолчанию создаёт 3 этапа-плейсхолдера (Подготовка / Основные работы / Сдача)', async () => {
    const { prisma, stages } = mkPrisma();
    const feed = mkFeed();
    const svc = new ProjectsService(prisma, feed, new FixedClock(NOW), mkChats(), mkCalculator());
    await svc.create({ ownerId: 'u', title: 'T' });
    expect(stages).toHaveLength(3);
    expect(stages.map((s: any) => s.title)).toEqual(['Подготовка', 'Основные работы', 'Сдача']);
    expect(stages.map((s: any) => s.orderIndex)).toEqual([0, 1, 2]);
    expect(feed.emit).toHaveBeenCalledWith(expect.objectContaining({ kind: 'stage_created' }));
  });

  it('initialStages=[] → проект создаётся без этапов', async () => {
    const { prisma, stages } = mkPrisma();
    const svc = new ProjectsService(
      prisma,
      mkFeed(),
      new FixedClock(NOW),
      mkChats(),
      mkCalculator(),
    );
    await svc.create({ ownerId: 'u', title: 'T', initialStages: [] });
    expect(stages).toHaveLength(0);
  });

  it('initialStages=[титулы] → создаёт ровно эти этапы в нужном порядке', async () => {
    const { prisma, stages } = mkPrisma();
    const svc = new ProjectsService(
      prisma,
      mkFeed(),
      new FixedClock(NOW),
      mkChats(),
      mkCalculator(),
    );
    await svc.create({
      ownerId: 'u',
      title: 'T',
      initialStages: ['Демонтаж', 'Электрика', 'Чистовая', 'Уборка'],
    });
    expect(stages.map((s: any) => s.title)).toEqual([
      'Демонтаж',
      'Электрика',
      'Чистовая',
      'Уборка',
    ]);
    expect(stages.map((s: any) => s.orderIndex)).toEqual([0, 1, 2, 3]);
  });

  it('validates plannedStart <= plannedEnd', async () => {
    const { prisma } = mkPrisma();
    const svc = new ProjectsService(
      prisma,
      mkFeed(),
      new FixedClock(NOW),
      mkChats(),
      mkCalculator(),
    );
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
    const svc = new ProjectsService(prisma, feed, new FixedClock(NOW), mkChats(), mkCalculator());
    const p = await svc.create({ ownerId: 'u', title: 'T' });
    const archived = await svc.archive(p.id, 'u');
    expect(archived.status).toBe('archived');
    expect(feed.emit).toHaveBeenCalledWith(expect.objectContaining({ kind: 'project_archived' }));
  });

  it('restore возвращает active', async () => {
    const { prisma } = mkPrisma();
    const svc = new ProjectsService(
      prisma,
      mkFeed(),
      new FixedClock(NOW),
      mkChats(),
      mkCalculator(),
    );
    const p = await svc.create({ ownerId: 'u', title: 'T' });
    await svc.archive(p.id, 'u');
    const restored = await svc.restore(p.id, 'u');
    expect(restored.status).toBe('active');
  });

  it('update на архивном проекте → 409', async () => {
    const { prisma } = mkPrisma();
    const svc = new ProjectsService(
      prisma,
      mkFeed(),
      new FixedClock(NOW),
      mkChats(),
      mkCalculator(),
    );
    const p = await svc.create({ ownerId: 'u', title: 'T' });
    await svc.archive(p.id, 'u');
    await expect(svc.update(p.id, { title: 'New' }, 'u')).rejects.toThrow(ConflictError);
  });

  it('archive → 404 для несуществующего', async () => {
    const { prisma } = mkPrisma();
    const svc = new ProjectsService(
      prisma,
      mkFeed(),
      new FixedClock(NOW),
      mkChats(),
      mkCalculator(),
    );
    await expect(svc.archive('p-missing', 'u')).rejects.toThrow(NotFoundError);
  });
});

describe('ProjectsService.copy — ТЗ §4.3', () => {
  it('копирует название (с суффиксом), этапы и плановые бюджеты; не копирует прогресс', async () => {
    const { prisma, projects, stages } = mkPrisma();
    const svc = new ProjectsService(
      prisma,
      mkFeed(),
      new FixedClock(NOW),
      mkChats(),
      mkCalculator(),
    );
    const src = await svc.create({
      ownerId: 'u',
      title: 'Оригинал',
      workBudget: 100_000,
      // Подавляем дефолтные 3 плейсхолдера — тест проверяет копирование
      // ровно одного «руками подсаженного» этапа.
      initialStages: [],
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
    const svc = new ProjectsService(
      prisma,
      mkFeed(),
      new FixedClock(NOW),
      mkChats(),
      mkCalculator(),
    );
    const src = await svc.create({ ownerId: 'u', title: 'Оригинал', initialStages: [] });
    const copy = await svc.copy(src.id, 'u', 'Кастомная копия');
    expect(copy.title).toBe('Кастомная копия');
  });

  it('копирует команду и pending-инвайты, переносит foremanIds через map (QA-баг #14)', async () => {
    const { prisma, memberships, invitations, stages } = mkPrisma();
    const svc = new ProjectsService(
      prisma,
      mkFeed(),
      new FixedClock(NOW),
      mkChats(),
      mkCalculator(),
    );
    const src = await svc.create({
      ownerId: 'owner',
      title: 'Оригинал',
      // Подавляем дефолтные 3 плейсхолдера — тест проверяет копирование
      // ровно одного руками подсаженного этапа (см. push'и ниже).
      initialStages: [],
    });
    // Команда: customer + foreman + master
    memberships.push(
      {
        id: 'm-existing-1',
        projectId: src.id,
        userId: 'owner',
        role: 'customer',
        stageIds: [],
        permissions: {},
        removedAt: null,
      },
      {
        id: 'm-existing-2',
        projectId: src.id,
        userId: 'foreman-1',
        role: 'foreman',
        stageIds: [],
        permissions: {},
        removedAt: null,
      },
      {
        id: 'm-existing-3',
        projectId: src.id,
        userId: 'master-1',
        role: 'master',
        stageIds: [],
        permissions: {},
        removedAt: null,
      },
    );
    // Один stage с назначенным бригадиром и мастером.
    stages.push({
      id: 'src-stage-1',
      projectId: src.id,
      title: 'Электрика',
      orderIndex: 0,
      plannedEnd: new Date('2026-07-01'),
      workBudget: BigInt(0),
      materialsBudget: BigInt(0),
      foremanIds: ['foreman-1'],
      masterId: 'master-1',
    });
    // Один pending-инвайт.
    invitations.push({
      id: 'inv-existing',
      projectId: src.id,
      phone: '+79990000099',
      role: 'foreman',
      invitedById: 'owner',
      status: 'pending',
      token: '111111',
      permissions: {},
      stageIds: [],
      expiresAt: new Date('2026-12-31'),
    });

    const copy = await svc.copy(src.id, 'owner');

    // 1. Команда полностью перенесена (3 membership) + сохранены роли.
    const copiedMembers = memberships.filter((m) => m.projectId === copy.id);
    expect(copiedMembers).toHaveLength(3);
    expect(copiedMembers.map((m) => m.role).sort()).toEqual(['customer', 'foreman', 'master']);
    // 2. Foreman/master переехали на скопированный этап.
    const copiedStages = stages.filter((s) => s.projectId === copy.id);
    expect(copiedStages).toHaveLength(1);
    expect(copiedStages[0].foremanIds).toEqual(['foreman-1']);
    expect(copiedStages[0].masterId).toBe('master-1');
    // 3. Pending-инвайт перенесён с новым уникальным токеном.
    const copiedInvites = invitations.filter((i) => i.projectId === copy.id);
    expect(copiedInvites).toHaveLength(1);
    expect(copiedInvites[0].token).not.toBe('111111');
    expect(copiedInvites[0].status).toBe('pending');
  });
});
