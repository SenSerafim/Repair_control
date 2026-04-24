import { AdminUsersService } from './admin-users.service';
import {
  ConflictError,
  FixedClock,
  ForbiddenError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { ConfigService } from '@nestjs/config';
import { AdminAuditService } from '../admin-audit/admin-audit.service';

interface U {
  id: string;
  phone: string;
  passwordHash: string;
  bannedAt: Date | null;
  banReason: string | null;
  activeRole: string;
  roles: { userId: string; role: string }[];
  createdAt: Date;
}

const mkPrisma = () => {
  const users = new Map<string, U>();
  const sessions: any[] = [];
  const audit: any[] = [];
  const userRoles: any[] = [];

  const prisma: any = {
    user: {
      findUnique: jest.fn(({ where, include }: any) => {
        const u = users.get(where.id);
        if (!u) return null;
        if (include?.roles) return { ...u, roles: u.roles };
        return u;
      }),
      update: jest.fn(({ where, data }: any) => {
        const u = users.get(where.id);
        if (!u) throw new Error('not found');
        Object.assign(u, data);
        return u;
      }),
      findMany: jest.fn(() => [...users.values()]),
      count: jest.fn(() => users.size),
    },
    session: {
      updateMany: jest.fn(({ where, data }: any) => {
        let count = 0;
        for (const s of sessions) {
          if (s.userId === where.userId && s.revokedAt == null) {
            Object.assign(s, data);
            count++;
          }
        }
        return { count };
      }),
    },
    userRole: {
      deleteMany: jest.fn(() => ({ count: 0 })),
      upsert: jest.fn(({ where, create }: any) => {
        const u = users.get(where.userId_role.userId);
        if (u && !u.roles.some((r) => r.role === where.userId_role.role)) {
          u.roles.push({ userId: u.id, role: where.userId_role.role });
        }
        return create;
      }),
    },
    adminAuditLog: {
      create: jest.fn(({ data }: any) => {
        audit.push(data);
        return data;
      }),
      findMany: jest.fn(() => audit),
    },
    $transaction: jest.fn(async (fn: any | any[]) => {
      if (typeof fn === 'function') return fn(prisma);
      return fn;
    }),
  };
  return { prisma: prisma as unknown as PrismaService, users, sessions, audit, userRoles };
};

const mkCfg = () =>
  ({
    get: (key: string, def?: any) => {
      if (key === 'BCRYPT_COST') return 4;
      return def;
    },
  }) as unknown as ConfigService;

const mkAudit = (prisma: PrismaService): AdminAuditService =>
  new AdminAuditService(prisma, new FixedClock(new Date()));

describe('AdminUsersService', () => {
  const seed = () => {
    const state = mkPrisma();
    state.users.set('admin', {
      id: 'admin',
      phone: '+0',
      passwordHash: 'h',
      bannedAt: null,
      banReason: null,
      activeRole: 'admin',
      roles: [{ userId: 'admin', role: 'admin' }],
      createdAt: new Date(),
    });
    state.users.set('u1', {
      id: 'u1',
      phone: '+1',
      passwordHash: 'h',
      bannedAt: null,
      banReason: null,
      activeRole: 'customer',
      roles: [{ userId: 'u1', role: 'customer' }],
      createdAt: new Date(),
    });
    return state;
  };

  it('ban — записывает bannedAt, banReason и ревокает сессии', async () => {
    const state = seed();
    state.sessions.push({ userId: 'u1', revokedAt: null });
    state.sessions.push({ userId: 'u1', revokedAt: null });
    const clock = new FixedClock(new Date('2026-08-10T10:00:00Z'));
    const svc = new AdminUsersService(state.prisma, clock, mkAudit(state.prisma), mkCfg());

    const r = await svc.ban('u1', 'admin', 'spam');
    expect(r.bannedAt).toEqual(clock.now());
    expect(r.banReason).toBe('spam');
    expect(state.sessions.every((s) => s.revokedAt != null)).toBe(true);
    expect(state.audit.some((a) => a.action === 'user.ban')).toBe(true);
  });

  it('ban — нельзя банить себя', async () => {
    const state = seed();
    const svc = new AdminUsersService(
      state.prisma,
      new FixedClock(new Date()),
      mkAudit(state.prisma),
      mkCfg(),
    );
    await expect(svc.ban('admin', 'admin', 'test')).rejects.toThrow(ForbiddenError);
  });

  it('ban — нельзя банить admin', async () => {
    const state = seed();
    state.users.set('admin2', {
      id: 'admin2',
      phone: '+2',
      passwordHash: 'h',
      bannedAt: null,
      banReason: null,
      activeRole: 'admin',
      roles: [{ userId: 'admin2', role: 'admin' }],
      createdAt: new Date(),
    });
    const svc = new AdminUsersService(
      state.prisma,
      new FixedClock(new Date()),
      mkAudit(state.prisma),
      mkCfg(),
    );
    await expect(svc.ban('admin2', 'admin', 'test')).rejects.toThrow(ForbiddenError);
  });

  it('ban — уже забаненный → ConflictError', async () => {
    const state = seed();
    state.users.get('u1')!.bannedAt = new Date();
    const svc = new AdminUsersService(
      state.prisma,
      new FixedClock(new Date()),
      mkAudit(state.prisma),
      mkCfg(),
    );
    await expect(svc.ban('u1', 'admin', 'dup')).rejects.toThrow(ConflictError);
  });

  it('unban — сбрасывает bannedAt', async () => {
    const state = seed();
    state.users.get('u1')!.bannedAt = new Date();
    state.users.get('u1')!.banReason = 'spam';
    const svc = new AdminUsersService(
      state.prisma,
      new FixedClock(new Date()),
      mkAudit(state.prisma),
      mkCfg(),
    );
    const r = await svc.unban('u1', 'admin');
    expect(r.bannedAt).toBeNull();
    expect(state.users.get('u1')!.bannedAt).toBeNull();
  });

  it('resetPassword — меняет hash и возвращает temp', async () => {
    const state = seed();
    const oldHash = state.users.get('u1')!.passwordHash;
    const svc = new AdminUsersService(
      state.prisma,
      new FixedClock(new Date()),
      mkAudit(state.prisma),
      mkCfg(),
    );
    const r = await svc.resetPassword('u1', 'admin');
    expect(r.tempPassword.length).toBeGreaterThan(6);
    expect(state.users.get('u1')!.passwordHash).not.toBe(oldHash);
  });

  it('forceLogout — revokes active sessions только у target', async () => {
    const state = seed();
    state.sessions.push({ userId: 'u1', revokedAt: null });
    state.sessions.push({ userId: 'u1', revokedAt: null });
    state.sessions.push({ userId: 'other', revokedAt: null });
    const svc = new AdminUsersService(
      state.prisma,
      new FixedClock(new Date()),
      mkAudit(state.prisma),
      mkCfg(),
    );
    const r = await svc.forceLogout('u1', 'admin');
    expect(r.revokedSessions).toBe(2);
    expect(state.sessions.find((s) => s.userId === 'other')!.revokedAt).toBeNull();
  });

  it('non-existent user → 404', async () => {
    const state = mkPrisma();
    const svc = new AdminUsersService(
      state.prisma,
      new FixedClock(new Date()),
      mkAudit(state.prisma),
      mkCfg(),
    );
    await expect(svc.ban('missing', 'admin', 'x')).rejects.toThrow(NotFoundError);
    await expect(svc.unban('missing', 'admin')).rejects.toThrow(NotFoundError);
    await expect(svc.resetPassword('missing', 'admin')).rejects.toThrow(NotFoundError);
  });
});
