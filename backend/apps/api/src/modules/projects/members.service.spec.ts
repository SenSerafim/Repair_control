import { MembersService } from './members.service';
import { FeedService } from '../feed/feed.service';
import {
  ConflictError,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';

const mkPrisma = () => {
  const memberships: any[] = [];
  const projects = new Map<string, any>();
  const stages: any[] = [];
  const approvals: any[] = [];
  const users: any[] = [];
  let id = 0;
  const prisma: any = {
    project: {
      // `collectRecipientUserIds` запрашивает `select: { ownerId, memberships }`
      // — мок должен подмешивать в результат активные memberships, иначе
      // tests на real-time broadcast падают на `for (m of project.memberships)`.
      findUnique: jest.fn(({ where, select }: any) => {
        const p = projects.get(where.id) ?? null;
        if (!p) return null;
        if (select?.memberships) {
          return {
            ...p,
            memberships: memberships
              .filter((m) => m.projectId === where.id && !m.removedAt)
              .map((m) => ({ userId: m.userId })),
          };
        }
        return p;
      }),
      update: jest.fn(({ where, data }: any) => {
        const p = projects.get(where.id);
        if (p) Object.assign(p, data);
        return p;
      }),
    },
    stage: {
      findMany: jest.fn(({ where }: any) =>
        stages.filter((s) => {
          if (where.projectId && s.projectId !== where.projectId) return false;
          if (where.status?.in && !where.status.in.includes(s.status)) return false;
          if (where.foremanIds?.has && !(s.foremanIds ?? []).includes(where.foremanIds.has)) {
            return false;
          }
          return true;
        }),
      ),
      update: jest.fn(({ where, data }: any) => {
        const s = stages.find((x) => x.id === where.id);
        if (s) Object.assign(s, data);
        return s;
      }),
    },
    approval: {
      updateMany: jest.fn(({ where, data }: any) => {
        const affected = approvals.filter((a) => {
          if (where.stageId && a.stageId !== where.stageId) return false;
          if (where.addresseeId && a.addresseeId !== where.addresseeId) return false;
          if (where.status && a.status !== where.status) return false;
          return true;
        });
        for (const a of affected) Object.assign(a, data);
        return { count: affected.length };
      }),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
    membership: {
      findFirst: jest.fn(({ where }: any) => {
        return (
          memberships.find((m) => {
            if (where.projectId && m.projectId !== where.projectId) return false;
            if (where.userId && m.userId !== where.userId) return false;
            if (where.role && m.role !== where.role) return false;
            if (where.removedAt === null && m.removedAt) return false;
            return true;
          }) ?? null
        );
      }),
      findUnique: jest.fn(({ where }: any) => {
        if (where.id) return memberships.find((m) => m.id === where.id) ?? null;
        const { projectId, userId, role } = where.projectId_userId_role;
        return (
          memberships.find(
            (m) => m.projectId === projectId && m.userId === userId && m.role === role,
          ) ?? null
        );
      }),
      create: jest.fn(({ data }: any) => {
        const m = { id: `m${++id}`, ...data };
        memberships.push(m);
        return m;
      }),
      update: jest.fn(({ where, data }: any) => {
        const m = memberships.find((x) => x.id === where.id);
        Object.assign(m, data);
        return m;
      }),
      delete: jest.fn(({ where }: any) => {
        const idx = memberships.findIndex((m) => m.id === where.id);
        if (idx >= 0) memberships.splice(idx, 1);
      }),
      findMany: jest.fn(({ where }: any) =>
        memberships.filter((m) => m.projectId === where.projectId),
      ),
    },
    user: {
      findFirst: jest.fn(({ where }: any) => {
        for (const or of where.OR as any[]) {
          if (!or) continue;
          if (or.phone) {
            const u = users.find((u) => u.phone === or.phone);
            if (u) return u;
          }
          if (or.email) {
            const u = users.find((u) => u.email === or.email);
            if (u) return u;
          }
        }
        return null;
      }),
    },
  };
  return {
    prisma: prisma as unknown as PrismaService,
    memberships,
    projects,
    stages,
    approvals,
    users,
  };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;
const mkChats = () =>
  ({
    ensureProjectChat: jest.fn().mockResolvedValue({}),
    addProjectChatParticipant: jest.fn().mockResolvedValue(undefined),
    removeProjectChatParticipant: jest.fn().mockResolvedValue(undefined),
    leaveAllChats: jest.fn().mockResolvedValue(undefined),
  }) as any;
// Минимальный stub EventEmitter2: фиксируем emit-вызовы, чтобы тест мог
// проверить, что MembersService шлёт `project.membership.changed`.
const mkEvents = () => ({ emit: jest.fn() }) as any;

describe('MembersService — self-foreman prohibition (ТЗ §1.5)', () => {
  it('нельзя назначить владельца бригадиром на его же проект', async () => {
    const { prisma, projects } = mkPrisma();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    const svc = new MembersService(prisma, mkFeed(), mkChats(), mkEvents());
    await expect(
      svc.addMembership({
        projectId: 'p1',
        actorUserId: 'u-owner',
        userId: 'u-owner',
        role: 'foreman',
      }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('добавление обычного бригадира работает', async () => {
    const { prisma, projects, memberships } = mkPrisma();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    const svc = new MembersService(prisma, mkFeed(), mkChats(), mkEvents());
    await svc.addMembership({
      projectId: 'p1',
      actorUserId: 'u-owner',
      userId: 'u-foreman',
      role: 'foreman',
    });
    expect(memberships[0]).toMatchObject({ role: 'foreman', userId: 'u-foreman' });
  });

  it('роль customer может быть только у владельца проекта', async () => {
    const { prisma, projects } = mkPrisma();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    const svc = new MembersService(prisma, mkFeed(), mkChats(), mkEvents());
    await expect(
      svc.addMembership({
        projectId: 'p1',
        actorUserId: 'u-owner',
        userId: 'u-someone',
        role: 'customer',
      }),
    ).rejects.toThrow(ForbiddenError);
  });

  it('повторное добавление активного участника → конфликт', async () => {
    const { prisma, projects } = mkPrisma();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    const svc = new MembersService(prisma, mkFeed(), mkChats(), mkEvents());
    await svc.addMembership({
      projectId: 'p1',
      actorUserId: 'u-owner',
      userId: 'u-rep',
      role: 'representative',
    });
    await expect(
      svc.addMembership({
        projectId: 'p1',
        actorUserId: 'u-owner',
        userId: 'u-rep',
        role: 'representative',
      }),
    ).rejects.toThrow(ConflictError);
  });

  it('soft-removed membership реанимируется при повторном add (фикс «уже в проекте»)', async () => {
    const { prisma, projects, memberships } = mkPrisma();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    memberships.push({ id: 'm-foreman', projectId: 'p1', userId: 'u-foreman', role: 'foreman' });
    // Имитация состояния после leaveTeam: запись осталась с removedAt!=null.
    memberships.push({
      id: 'm-old',
      projectId: 'p1',
      userId: 'u-master',
      role: 'master',
      stageIds: [],
      removedAt: new Date('2026-05-13T10:00:00Z'),
      removedById: 'u-master',
    });
    const svc = new MembersService(prisma, mkFeed(), mkChats(), mkEvents());

    const result = await svc.addMembership({
      projectId: 'p1',
      actorUserId: 'u-foreman',
      userId: 'u-master',
      role: 'master',
    });

    // Реанимация той же строки, не дубль.
    expect((result as any).id).toBe('m-old');
    expect(memberships).toHaveLength(2);
    const restored = memberships.find((m) => m.id === 'm-old')!;
    expect(restored.removedAt).toBeNull();
    expect(restored.invitedById).toBe('u-foreman');
  });

  it('несуществующий проект → 404', async () => {
    const { prisma } = mkPrisma();
    const svc = new MembersService(prisma, mkFeed(), mkChats(), mkEvents());
    await expect(
      svc.addMembership({
        projectId: 'p-missing',
        actorUserId: 'u1',
        userId: 'u2',
        role: 'foreman',
      }),
    ).rejects.toThrow(NotFoundError);
  });

  it('санитизирует permissions для representative (только известные ключи, только boolean)', async () => {
    const { prisma, projects, memberships } = mkPrisma();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    const svc = new MembersService(prisma, mkFeed(), mkChats(), mkEvents());
    await svc.addMembership({
      projectId: 'p1',
      actorUserId: 'u-owner',
      userId: 'u-rep',
      role: 'representative',
      permissions: {
        canApprove: true,
        canEditStages: 'yes', // не boolean
        unknownKey: true, // не в списке
      } as any,
    });
    const perms = memberships[0].permissions;
    expect(perms.canApprove).toBe(true);
    expect(perms.canEditStages).toBe(false); // дефолт, т.к. не boolean
    expect(perms.unknownKey).toBeUndefined();
  });
});

describe('MembersService.searchUser', () => {
  it('находит по телефону', async () => {
    const { prisma, users } = mkPrisma();
    users.push({ id: 'u1', phone: '+79991112233', email: 'x@y.z' });
    const svc = new MembersService(prisma, mkFeed(), mkChats(), mkEvents());
    await expect(svc.searchUser({ phone: '+79991112233' })).resolves.toMatchObject({ id: 'u1' });
  });
  it('null если не передали ни phone, ни email', async () => {
    const { prisma } = mkPrisma();
    const svc = new MembersService(prisma, mkFeed(), mkChats(), mkEvents());
    await expect(svc.searchUser({})).resolves.toBeNull();
  });
});

describe('MembersService.removeMembership', () => {
  it('нельзя удалить owner-membership', async () => {
    const { prisma, projects, memberships } = mkPrisma();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    memberships.push({ id: 'm1', projectId: 'p1', userId: 'u-owner', role: 'customer' });
    const svc = new MembersService(prisma, mkFeed(), mkChats(), mkEvents());
    await expect(svc.removeMembership('p1', 'm1', 'u-owner')).rejects.toThrow(InvalidInputError);
  });

  it('H.2: удаление foreman активной стадии помечает его pending approvals requiresReassign + emit foreman_removed', async () => {
    const { prisma, projects, memberships, stages, approvals } = mkPrisma();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    memberships.push({ id: 'mf', projectId: 'p1', userId: 'f1', role: 'foreman' });
    stages.push({
      id: 's1',
      projectId: 'p1',
      status: 'active',
      foremanIds: ['f1'],
    });
    approvals.push({
      id: 'ap1',
      stageId: 's1',
      addresseeId: 'f1',
      status: 'pending',
      requiresReassign: false,
    });
    const feed = mkFeed();
    const svc = new MembersService(prisma, feed, mkChats(), mkEvents());
    await svc.removeMembership('p1', 'mf', 'u-owner');
    expect(approvals[0].requiresReassign).toBe(true);
    const kinds = (feed.emit as jest.Mock).mock.calls.map((c) => c[0].kind);
    expect(kinds).toContain('foreman_removed');
    expect(kinds).toContain('membership_removed');
    // Мастера не должны быть автоматически удалены (не добавлялись в этом тесте — просто проверяем что foreman исчез)
    expect(memberships.find((m) => m.id === 'mf')).toBeUndefined();
  });
});

describe('MembersService — real-time membership broadcast (ТЗ §13.2)', () => {
  it('addMembership эмитит project.membership.changed со списком recipients', async () => {
    const { prisma, projects, memberships } = mkPrisma();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    // У проекта уже есть owner-membership + бригадир: мастер добавляется
    // бригадиром, заказчик мастеров не добавляет.
    memberships.push({ id: 'm0', projectId: 'p1', userId: 'u-owner', role: 'customer' });
    memberships.push({ id: 'm1', projectId: 'p1', userId: 'u-foreman1', role: 'foreman' });
    const events = mkEvents();
    const svc = new MembersService(prisma, mkFeed(), mkChats(), events);

    await svc.addMembership({
      projectId: 'p1',
      actorUserId: 'u-foreman1',
      userId: 'u-master',
      role: 'master',
    });

    const calls = (events.emit as jest.Mock).mock.calls;
    const changed = calls.find((c) => c[0] === 'project.membership.changed');
    expect(changed).toBeDefined();
    const payload = changed![1];
    expect(payload.projectId).toBe('p1');
    expect(payload.userId).toBe('u-master');
    expect(payload.action).toBe('added');
    expect(payload.role).toBe('master');
    // recipients: owner + foreman1 + новый master (тихий WS летит всем сразу).
    expect(payload.recipientUserIds).toEqual(
      expect.arrayContaining(['u-owner', 'u-foreman1', 'u-master']),
    );
  });

  it('removeMembership эмитит project.membership.changed с action=removed', async () => {
    const { prisma, projects, memberships } = mkPrisma();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    memberships.push({ id: 'm0', projectId: 'p1', userId: 'u-owner', role: 'customer' });
    memberships.push({ id: 'mr', projectId: 'p1', userId: 'u-rep', role: 'representative' });
    const events = mkEvents();
    const svc = new MembersService(prisma, mkFeed(), mkChats(), events);

    await svc.removeMembership('p1', 'mr', 'u-owner');

    const changed = (events.emit as jest.Mock).mock.calls.find(
      (c) => c[0] === 'project.membership.changed',
    );
    expect(changed).toBeDefined();
    const payload = changed![1];
    expect(payload.userId).toBe('u-rep');
    expect(payload.action).toBe('removed');
    expect(payload.recipientUserIds).toEqual(expect.arrayContaining(['u-rep', 'u-owner']));
  });
});
