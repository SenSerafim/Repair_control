import { Test } from '@nestjs/testing';
import { Clock, FixedClock, PrismaService } from '@app/common';
import { FeedService } from '../feed/feed.service';
import { MaterialsScheduler } from './materials.scheduler';

const NOW = new Date('2026-06-15T10:00:00Z');
const START_OF_DAY = new Date('2026-06-15T00:00:00Z');
START_OF_DAY.setHours(0, 0, 0, 0);

const mkPrisma = () => {
  const requests: Array<{
    id: string;
    projectId: string;
    stageId: string | null;
    title: string;
    items: Array<{ id: string; name: string; dueDate: Date | null }>;
  }> = [];
  const emittedFeed: Array<{ projectId: string; requestId: string; createdAt: Date }> = [];

  const prisma: any = {
    materialRequest: {
      findMany: jest.fn(({ where }: any) =>
        requests.filter((r) => {
          if (where.status && where.status !== 'open') return false;
          if (where.items?.some?.dueDate?.lt) {
            const limit = where.items.some.dueDate.lt;
            return r.items.some((i) => i.dueDate && i.dueDate < limit);
          }
          return true;
        }),
      ),
    },
    feedEvent: {
      findFirst: jest.fn(({ where }: any) => {
        const requestId = where?.payload?.equals;
        const gte = where?.createdAt?.gte;
        return (
          emittedFeed.find(
            (e) =>
              e.projectId === where.projectId &&
              e.requestId === requestId &&
              (!gte || e.createdAt >= gte),
          ) ?? null
        );
      }),
    },
  };
  return { prisma: prisma as unknown as PrismaService, requests, emittedFeed };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

describe('MaterialsScheduler.flagOverdueRequests', () => {
  let scheduler: MaterialsScheduler;
  let prismaCtx: ReturnType<typeof mkPrisma>;
  let feed: FeedService;
  let clock: FixedClock;

  beforeEach(async () => {
    prismaCtx = mkPrisma();
    feed = mkFeed();
    clock = new FixedClock(NOW);
    const module = await Test.createTestingModule({
      providers: [
        MaterialsScheduler,
        { provide: PrismaService, useValue: prismaCtx.prisma },
        { provide: Clock, useValue: clock },
        { provide: FeedService, useValue: feed },
      ],
    }).compile();
    scheduler = module.get(MaterialsScheduler);
  });

  it('эмитит material_request_overdue для заявки с просроченной позицией', async () => {
    prismaCtx.requests.push({
      id: 'r1',
      projectId: 'p1',
      stageId: 's1',
      title: 'Электрика',
      items: [{ id: 'i1', name: 'Кабель', dueDate: new Date('2026-06-10T00:00:00Z') }],
    });

    await scheduler.flagOverdueRequests();

    expect(feed.emit).toHaveBeenCalledTimes(1);
    expect(feed.emit).toHaveBeenCalledWith(
      expect.objectContaining({
        kind: 'material_request_overdue',
        projectId: 'p1',
        stageId: 's1',
        payload: expect.objectContaining({
          requestId: 'r1',
          title: 'Электрика',
          overdueItemCount: 1,
        }),
      }),
    );
  });

  it('idempotent: если за сегодня уже было событие — не эмитит повторно', async () => {
    prismaCtx.requests.push({
      id: 'r1',
      projectId: 'p1',
      stageId: null,
      title: 'X',
      items: [{ id: 'i1', name: 'X', dueDate: new Date('2026-06-10') }],
    });
    prismaCtx.emittedFeed.push({
      projectId: 'p1',
      requestId: 'r1',
      createdAt: new Date('2026-06-15T08:00:00Z'),
    });

    await scheduler.flagOverdueRequests();

    expect(feed.emit).not.toHaveBeenCalled();
  });

  it('пропускает заявки без просроченных позиций (защита от ложных срабатываний)', async () => {
    prismaCtx.requests.push({
      id: 'r1',
      projectId: 'p1',
      stageId: null,
      title: 'X',
      items: [{ id: 'i1', name: 'X', dueDate: new Date('2026-06-20T00:00:00Z') }], // в будущем
    });
    // mock findMany возвращает только те, что подходят под фильтр items.some.dueDate.lt
    await scheduler.flagOverdueRequests();
    expect(feed.emit).not.toHaveBeenCalled();
  });

  it('обрабатывает несколько заявок независимо', async () => {
    prismaCtx.requests.push(
      {
        id: 'r1',
        projectId: 'p1',
        stageId: 's1',
        title: 'A',
        items: [{ id: 'i1', name: 'X', dueDate: new Date('2026-06-10') }],
      },
      {
        id: 'r2',
        projectId: 'p2',
        stageId: null,
        title: 'B',
        items: [{ id: 'i2', name: 'Y', dueDate: new Date('2026-06-12') }],
      },
    );

    await scheduler.flagOverdueRequests();

    expect(feed.emit).toHaveBeenCalledTimes(2);
  });

  it('логирует и продолжает, если emit для одной заявки фейлит', async () => {
    prismaCtx.requests.push(
      {
        id: 'r-broken',
        projectId: 'p1',
        stageId: null,
        title: 'A',
        items: [{ id: 'i1', name: 'X', dueDate: new Date('2026-06-10') }],
      },
      {
        id: 'r-ok',
        projectId: 'p2',
        stageId: null,
        title: 'B',
        items: [{ id: 'i2', name: 'Y', dueDate: new Date('2026-06-11') }],
      },
    );
    (feed.emit as jest.Mock)
      .mockRejectedValueOnce(new Error('boom'))
      .mockResolvedValueOnce(undefined);

    await scheduler.flagOverdueRequests();

    expect(feed.emit).toHaveBeenCalledTimes(2);
  });
});
