import { MembersService } from './members.service';
import { FeedService } from '../feed/feed.service';
import { PrismaService } from '@app/common';

/**
 * Видимость команды.
 *
 * 2026-05-13 раунд: заказчик подтвердил «мастер — одна сущность, видна всем
 * в команде проекта независимо от того, кто его пригласил» (см. members.service.ts:
 * applyVisibility). Прежняя §1.4-иерархия (invitedById-фильтр у заказчика,
 * stage-intersection у бригадира/мастера) снята. Тесты бьют по чистому методу
 * `MembersService.applyVisibility(...)` — единому источнику правил, который
 * вызывается и `listVisibleForViewer`, и `UsersService.listTeammates`.
 */
type M = {
  id: string;
  userId: string;
  role: 'customer' | 'representative' | 'foreman' | 'master';
  invitedById: string | null;
  stageIds: string[];
  permissions: Record<string, unknown>;
};

const m = (override: Partial<M> & Pick<M, 'id' | 'userId' | 'role'>): M => ({
  invitedById: null,
  stageIds: [],
  permissions: {},
  ...override,
});

const mkSvc = (stages: { id: string; foremanIds: string[] }[] = []) => {
  const prisma: any = {
    stage: {
      findMany: jest.fn(({ where, select }: any) => {
        let rows = stages;
        if (where.foremanIds?.has) {
          rows = rows.filter((s) => s.foremanIds.includes(where.foremanIds.has));
        }
        if (where.id?.in) {
          rows = rows.filter((s) => where.id.in.includes(s.id));
        }
        // Возвращаем только запрошенные поля (id обязательно).
        if (select?.foremanIds) return rows.map((s) => ({ id: s.id, foremanIds: s.foremanIds }));
        return rows.map((s) => ({ id: s.id }));
      }),
    },
  };
  const feed = { emit: jest.fn().mockResolvedValue(undefined) } as unknown as FeedService;
  const chats = { ensureProjectChat: jest.fn() } as any;
  const events = { emit: jest.fn() } as any;
  return new MembersService(prisma as PrismaService, feed, chats, events);
};

const visibleUserIds = (rows: M[]) => rows.map((r) => r.userId).sort();

describe('MembersService.applyVisibility — единая команда (2026-05-13)', () => {
  const owner = 'u-owner';
  const foreman = 'u-foreman';
  const otherForeman = 'u-other-foreman';
  const repPlain = 'u-rep';
  const masterByOwner = 'u-master-own';
  const masterByForeman = 'u-master-foreman';
  const otherStageMaster = 'u-other-master';

  const memberships: M[] = [
    m({ id: 'm1', userId: owner, role: 'customer' }),
    m({ id: 'm2', userId: foreman, role: 'foreman', invitedById: owner }),
    m({ id: 'm3', userId: otherForeman, role: 'foreman', invitedById: owner }),
    m({ id: 'm4', userId: repPlain, role: 'representative', permissions: {} }),
    m({
      id: 'm5',
      userId: masterByOwner,
      role: 'master',
      invitedById: owner,
      stageIds: ['s-direct'],
    }),
    m({
      id: 'm6',
      userId: masterByForeman,
      role: 'master',
      invitedById: foreman,
      stageIds: ['s-foreman'],
    }),
    m({
      id: 'm7',
      userId: otherStageMaster,
      role: 'master',
      invitedById: otherForeman,
      stageIds: ['s-other'],
    }),
  ];

  it('заказчик видит только заказчика, представителей и бригадиров', async () => {
    const svc = mkSvc();
    const out = await svc.applyVisibility(memberships, owner, owner, 'p1');
    expect(visibleUserIds(out)).toEqual([owner, foreman, otherForeman, repPlain].sort());
  });

  it('owner без явной customer-membership тоже не видит мастеров', async () => {
    const svc = mkSvc();
    const trimmed = memberships.filter((x) => x.role !== 'customer');
    const out = await svc.applyVisibility(trimmed, owner, owner, 'p1');
    expect(visibleUserIds(out)).toEqual([foreman, otherForeman, repPlain].sort());
  });

  it('представитель не видит мастеров', async () => {
    const svc = mkSvc();
    const out = await svc.applyVisibility(memberships, repPlain, owner, 'p1');
    expect(visibleUserIds(out)).toEqual([owner, foreman, otherForeman, repPlain].sort());
  });

  it('бригадир видит мастеров другого бригадира', async () => {
    const svc = mkSvc();
    const out = await svc.applyVisibility(memberships, foreman, owner, 'p1');
    const ids = visibleUserIds(out);
    expect(ids).toContain(otherStageMaster);
    expect(ids).toContain(masterByOwner);
  });

  it('мастер видит всю команду проекта, включая мастеров других этапов', async () => {
    const svc = mkSvc();
    const out = await svc.applyVisibility(memberships, masterByForeman, owner, 'p1');
    const ids = visibleUserIds(out);
    expect(ids).toContain(otherStageMaster);
    expect(ids).toContain(masterByOwner);
    expect(ids).toContain(owner);
  });

  it('outsider (не участник проекта) → пустой список', async () => {
    const svc = mkSvc();
    const out = await svc.applyVisibility(memberships, 'u-stranger', owner, 'p1');
    expect(out).toEqual([]);
  });
});

/**
 * ТЗ §1.4: «Чат проекта = заказчик + бригадиры. Чат этапа = бригадир + его
 * мастера». Мастер не должен попадать в project-чат, иначе заказчик видит его
 * через chat:participants и обходит §1.4-фильтр на /members.
 */
describe('MembersService.addMembership — chat participant rules (ТЗ §1.4)', () => {
  const mkAddSvc = () => {
    const memberships: any[] = [];
    const projects = new Map<string, any>();
    const prisma: any = {
      project: {
        findUnique: jest.fn(({ where }: any) => projects.get(where.id) ?? null),
        update: jest.fn(({ where, data }: any) => {
          const p = projects.get(where.id);
          if (p) Object.assign(p, data);
          return p;
        }),
      },
      membership: {
        findUnique: jest.fn(({ where }: any) => {
          const { projectId, userId, role } = where.projectId_userId_role;
          return (
            memberships.find(
              (mm) => mm.projectId === projectId && mm.userId === userId && mm.role === role,
            ) ?? null
          );
        }),
        findFirst: jest.fn(
          ({ where }: any) =>
            memberships.find(
              (mm) =>
                mm.projectId === where.projectId &&
                mm.userId === where.userId &&
                mm.removedAt == null,
            ) ?? null,
        ),
        create: jest.fn(({ data }: any) => {
          const row = { id: `m${memberships.length + 1}`, ...data };
          memberships.push(row);
          return row;
        }),
      },
      $transaction: jest.fn(async (fn: any) => fn(prisma)),
    };
    const feed = { emit: jest.fn().mockResolvedValue(undefined) } as unknown as FeedService;
    const chats = {
      ensureProjectChat: jest.fn().mockResolvedValue({}),
      addProjectChatParticipant: jest.fn().mockResolvedValue({}),
    } as any;
    const events = {
      emit: jest.fn(),
    } as any;
    const svc = new MembersService(prisma as PrismaService, feed, chats, events);
    // collectRecipientUserIds зовёт project.findUnique с include:memberships —
    // дополним мок:
    prisma.project.findUnique.mockImplementation(({ where, select }: any) => {
      const p = projects.get(where.id);
      if (!p) return null;
      if (select?.memberships) {
        return {
          ...p,
          memberships: memberships
            .filter((mm) => mm.projectId === where.id && mm.removedAt == null)
            .map((mm) => ({ userId: mm.userId })),
        };
      }
      return p;
    });
    return { svc, chats, projects, memberships };
  };

  it('foreman добавлен в project-чат', async () => {
    const { svc, chats, projects } = mkAddSvc();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    await svc.addMembership({
      projectId: 'p1',
      actorUserId: 'u-owner',
      userId: 'u-foreman',
      role: 'foreman',
    });
    expect(chats.addProjectChatParticipant).toHaveBeenCalledWith('p1', 'u-foreman');
  });

  it('representative добавлен в project-чат', async () => {
    const { svc, chats, projects } = mkAddSvc();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    await svc.addMembership({
      projectId: 'p1',
      actorUserId: 'u-owner',
      userId: 'u-rep',
      role: 'representative',
    });
    expect(chats.addProjectChatParticipant).toHaveBeenCalledWith('p1', 'u-rep');
  });

  it('master добавлен в общий project-чат (один чат на всех)', async () => {
    // По текущему решению заказчика — у проекта один общий чат для всей
    // команды (см. chats.service.ts: seedProjectParticipants и фильтр
    // listForProject без stage). Master должен получить доступ к чату со
    // всей историей сообщений сразу после добавления в команду.
    const { svc, chats, projects, memberships } = mkAddSvc();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    memberships.push({
      id: 'mf',
      projectId: 'p1',
      userId: 'u-foreman',
      role: 'foreman',
      removedAt: null,
    });
    await svc.addMembership({
      projectId: 'p1',
      actorUserId: 'u-foreman',
      userId: 'u-master',
      role: 'master',
    });
    expect(chats.addProjectChatParticipant).toHaveBeenCalledWith('p1', 'u-master');
  });

  it('foreman НЕ может пригласить representative (ТЗ §1.5)', async () => {
    const { svc, projects, memberships } = mkAddSvc();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    memberships.push({
      id: 'mf',
      projectId: 'p1',
      userId: 'u-foreman',
      role: 'foreman',
      removedAt: null,
    });
    await expect(
      svc.addMembership({
        projectId: 'p1',
        actorUserId: 'u-foreman',
        userId: 'u-rep',
        role: 'representative',
      }),
    ).rejects.toThrow(/foreman can invite only masters/);
  });

  it('foreman НЕ может пригласить другого foreman (ТЗ §1.5)', async () => {
    const { svc, projects, memberships } = mkAddSvc();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    memberships.push({
      id: 'mf',
      projectId: 'p1',
      userId: 'u-foreman',
      role: 'foreman',
      removedAt: null,
    });
    await expect(
      svc.addMembership({
        projectId: 'p1',
        actorUserId: 'u-foreman',
        userId: 'u-foreman2',
        role: 'foreman',
      }),
    ).rejects.toThrow(/foreman can invite only masters/);
  });
});
