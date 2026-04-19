import { UsersService } from './users.service';
import { ConflictError, InvalidInputError, NotFoundError, PrismaService } from '@app/common';

interface Fake {
  users: Map<string, any>;
  roles: { userId: string; role: string; addedAt: Date; isActive: boolean }[];
  devices: any[];
}

const mkPrisma = () => {
  const state: Fake = { users: new Map(), roles: [], devices: [] };
  const prisma: any = {
    user: {
      findUnique: jest.fn(({ where, include }: any) => {
        const u = state.users.get(where.id);
        if (!u) return null;
        return {
          ...u,
          roles: include?.roles ? state.roles.filter((r) => r.userId === where.id) : undefined,
          devices: include?.devices
            ? state.devices.filter((d) => d.userId === where.id)
            : undefined,
        };
      }),
      update: jest.fn(({ where, data, select }: any) => {
        const u = state.users.get(where.id);
        Object.assign(u, data);
        return select ? u : u;
      }),
    },
    userRole: {
      findUnique: jest.fn(({ where }: any) => {
        const { userId, role } = where.userId_role;
        return state.roles.find((r) => r.userId === userId && r.role === role) ?? null;
      }),
      findMany: jest.fn(({ where }: any) => state.roles.filter((r) => r.userId === where.userId)),
      create: jest.fn(({ data }: any) => {
        const r = { ...data, addedAt: new Date(), isActive: true };
        state.roles.push(r);
        return r;
      }),
      delete: jest.fn(({ where }: any) => {
        const { userId, role } = where.userId_role;
        const idx = state.roles.findIndex((r) => r.userId === userId && r.role === role);
        if (idx >= 0) state.roles.splice(idx, 1);
      }),
    },
    deviceToken: {
      upsert: jest.fn(({ create, update, where }: any) => {
        const existing = state.devices.find((d) => d.token === where.token);
        if (existing) {
          Object.assign(existing, update);
          return existing;
        }
        state.devices.push(create);
        return create;
      }),
    },
  };
  return { prisma: prisma as unknown as PrismaService, state };
};

describe('UsersService.addRole', () => {
  it('добавляет новую роль', async () => {
    const { prisma, state } = mkPrisma();
    state.users.set('u1', { id: 'u1', activeRole: 'customer' });
    state.roles.push({ userId: 'u1', role: 'customer', addedAt: new Date(), isActive: true });
    const svc = new UsersService(prisma);
    await svc.addRole('u1', 'contractor');
    expect(state.roles.some((r) => r.role === 'contractor')).toBe(true);
  });

  it('конфликт: роль уже есть', async () => {
    const { prisma, state } = mkPrisma();
    state.users.set('u1', { id: 'u1' });
    state.roles.push({ userId: 'u1', role: 'customer', addedAt: new Date(), isActive: true });
    const svc = new UsersService(prisma);
    await expect(svc.addRole('u1', 'customer')).rejects.toThrow(ConflictError);
  });

  it('нельзя самостоятельно назначать admin', async () => {
    const { prisma } = mkPrisma();
    const svc = new UsersService(prisma);
    await expect(svc.addRole('u1', 'admin')).rejects.toThrow(InvalidInputError);
  });
});

describe('UsersService.removeRole', () => {
  it('удаляет роль и переключает active на оставшуюся', async () => {
    const { prisma, state } = mkPrisma();
    state.users.set('u1', { id: 'u1', activeRole: 'customer' });
    state.roles.push(
      { userId: 'u1', role: 'customer', addedAt: new Date(), isActive: true },
      { userId: 'u1', role: 'contractor', addedAt: new Date(), isActive: true },
    );
    const svc = new UsersService(prisma);
    await svc.removeRole('u1', 'customer');
    expect(state.roles.find((r) => r.role === 'customer')).toBeUndefined();
    expect(state.users.get('u1').activeRole).toBe('contractor');
  });

  it('нельзя удалить последнюю роль', async () => {
    const { prisma, state } = mkPrisma();
    state.users.set('u1', { id: 'u1', activeRole: 'customer' });
    state.roles.push({ userId: 'u1', role: 'customer', addedAt: new Date(), isActive: true });
    const svc = new UsersService(prisma);
    await expect(svc.removeRole('u1', 'customer')).rejects.toThrow(InvalidInputError);
  });

  it('404 на несуществующую роль', async () => {
    const { prisma, state } = mkPrisma();
    state.users.set('u1', { id: 'u1' });
    state.roles.push({ userId: 'u1', role: 'customer', addedAt: new Date(), isActive: true });
    const svc = new UsersService(prisma);
    await expect(svc.removeRole('u1', 'master')).rejects.toThrow(NotFoundError);
  });
});

describe('UsersService.setActiveRole', () => {
  it('переключает active если роль у пользователя есть', async () => {
    const { prisma, state } = mkPrisma();
    state.users.set('u1', { id: 'u1', activeRole: 'customer' });
    state.roles.push(
      { userId: 'u1', role: 'customer', addedAt: new Date(), isActive: true },
      { userId: 'u1', role: 'contractor', addedAt: new Date(), isActive: true },
    );
    const svc = new UsersService(prisma);
    const res = await svc.setActiveRole('u1', 'contractor');
    expect(res.activeRole).toBe('contractor');
  });

  it('404 если роль не добавлена', async () => {
    const { prisma, state } = mkPrisma();
    state.users.set('u1', { id: 'u1', activeRole: 'customer' });
    state.roles.push({ userId: 'u1', role: 'customer', addedAt: new Date(), isActive: true });
    const svc = new UsersService(prisma);
    await expect(svc.setActiveRole('u1', 'master')).rejects.toThrow(NotFoundError);
  });
});

describe('UsersService.registerDevice', () => {
  it('upsert по токену', async () => {
    const { prisma, state } = mkPrisma();
    const svc = new UsersService(prisma);
    await svc.registerDevice('u1', { platform: 'ios', token: 'abcdef0123456789' });
    expect(state.devices.length).toBe(1);
    // повторный upsert не создаёт дубликат
    await svc.registerDevice('u1', { platform: 'ios', token: 'abcdef0123456789' });
    expect(state.devices.length).toBe(1);
  });
});
