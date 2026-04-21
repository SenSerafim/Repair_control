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
  const users: any[] = [];
  let id = 0;
  const prisma: any = {
    project: {
      findUnique: jest.fn(({ where }: any) => projects.get(where.id) ?? null),
      update: jest.fn(({ where, data }: any) => {
        const p = projects.get(where.id);
        if (p) Object.assign(p, data);
        return p;
      }),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
    membership: {
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
  return { prisma: prisma as unknown as PrismaService, memberships, projects, users };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

describe('MembersService — self-foreman prohibition (ТЗ §1.5)', () => {
  it('нельзя назначить владельца бригадиром на его же проект', async () => {
    const { prisma, projects } = mkPrisma();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    const svc = new MembersService(prisma, mkFeed());
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
    const svc = new MembersService(prisma, mkFeed());
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
    const svc = new MembersService(prisma, mkFeed());
    await expect(
      svc.addMembership({
        projectId: 'p1',
        actorUserId: 'u-owner',
        userId: 'u-someone',
        role: 'customer',
      }),
    ).rejects.toThrow(ForbiddenError);
  });

  it('повторное добавление → конфликт', async () => {
    const { prisma, projects } = mkPrisma();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    const svc = new MembersService(prisma, mkFeed());
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

  it('несуществующий проект → 404', async () => {
    const { prisma } = mkPrisma();
    const svc = new MembersService(prisma, mkFeed());
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
    const svc = new MembersService(prisma, mkFeed());
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
    const svc = new MembersService(prisma, mkFeed());
    await expect(svc.searchUser({ phone: '+79991112233' })).resolves.toMatchObject({ id: 'u1' });
  });
  it('null если не передали ни phone, ни email', async () => {
    const { prisma } = mkPrisma();
    const svc = new MembersService(prisma, mkFeed());
    await expect(svc.searchUser({})).resolves.toBeNull();
  });
});

describe('MembersService.removeMembership', () => {
  it('нельзя удалить owner-membership', async () => {
    const { prisma, projects, memberships } = mkPrisma();
    projects.set('p1', { id: 'p1', ownerId: 'u-owner' });
    memberships.push({ id: 'm1', projectId: 'p1', userId: 'u-owner', role: 'customer' });
    const svc = new MembersService(prisma, mkFeed());
    await expect(svc.removeMembership('p1', 'm1', 'u-owner')).rejects.toThrow(InvalidInputError);
  });
});
