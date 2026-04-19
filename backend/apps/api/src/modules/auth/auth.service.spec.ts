import * as bcrypt from 'bcrypt';
import { AuthService } from './auth.service';
import { TokenService } from './token.service';
import { AuthError, ConflictError, FixedClock, PrismaService } from '@app/common';

const makeConfig = () => ({
  get: (k: string, def?: any) => {
    if (k === 'BCRYPT_COST') return 4; // быстрый хэш для тестов
    if (k === 'JWT_REFRESH_TTL') return 2_592_000;
    if (k === 'JWT_ACCESS_TTL') return 900;
    if (k === 'RATE_LIMIT_LOGIN_MAX') return 3;
    if (k === 'RATE_LIMIT_LOGIN_WINDOW_SECONDS') return 300;
    return def;
  },
});

const mkPrisma = () => {
  const users = new Map<string, any>();
  const sessions = new Map<string, any>();
  const loginAttempts: any[] = [];
  let idSeq = 0;

  const prisma: any = {
    user: {
      findUnique: jest.fn(({ where }: any) =>
        Promise.resolve(
          users.get(where.phone) ?? [...users.values()].find((u) => u.id === where.id) ?? null,
        ),
      ),
      create: jest.fn(({ data }: any) => {
        const id = `u${++idSeq}`;
        const u = { id, ...data, activeRole: data.activeRole, createdAt: new Date() };
        users.set(u.phone, u);
        return Promise.resolve(u);
      }),
      update: jest.fn(({ where, data }: any) => {
        const u = [...users.values()].find((x) => x.id === where.id);
        Object.assign(u, data);
        return Promise.resolve(u);
      }),
    },
    session: {
      create: jest.fn(({ data }: any) => {
        const id = `s${sessions.size + 1}`;
        const s = { id, ...data, createdAt: new Date() };
        sessions.set(id, s);
        return Promise.resolve(s);
      }),
      findUnique: jest.fn(({ where }: any) => Promise.resolve(sessions.get(where.id) ?? null)),
      update: jest.fn(({ where, data }: any) => {
        const s = sessions.get(where.id);
        Object.assign(s, data);
        return Promise.resolve(s);
      }),
      updateMany: jest.fn(async ({ where, data }: any) => {
        let count = 0;
        for (const s of sessions.values()) {
          if (s.id === where.id && s.revokedAt === null) {
            Object.assign(s, data);
            count++;
          }
        }
        return { count };
      }),
    },
    loginAttempt: {
      create: jest.fn(({ data }: any) => {
        loginAttempts.push({ ...data, createdAt: new Date() });
        return Promise.resolve(data);
      }),
      count: jest.fn(({ where }: any) => {
        const since = where.createdAt?.gte ?? new Date(0);
        const match = loginAttempts.filter(
          (a) =>
            !a.success &&
            a.createdAt >= since &&
            (where.OR?.some?.((c: any) => c.phone === a.phone || c.ip === a.ip) ?? true),
        );
        return Promise.resolve(match.length);
      }),
    },
  };
  return { prisma: prisma as unknown as PrismaService, users, sessions, loginAttempts };
};

const mkTokens = (): TokenService =>
  ({
    signAccess: jest.fn().mockResolvedValue('access-jwt'),
    signRefresh: jest.fn().mockResolvedValue('refresh-jwt'),
    verifyRefresh: jest.fn().mockResolvedValue({ sub: 'u1', sid: 's1' }),
    hashRefresh: jest.fn().mockResolvedValue('refresh-hash'),
    compareRefresh: jest.fn().mockResolvedValue(true),
  }) as unknown as TokenService;

describe('AuthService.register', () => {
  it('создаёт пользователя и выдаёт токены', async () => {
    const { prisma } = mkPrisma();
    const tokens = mkTokens();
    const svc = new AuthService(prisma, tokens, makeConfig() as any, new FixedClock(new Date()));
    const res = await svc.register({
      phone: '+79991112233',
      password: 'qwerty123',
      firstName: 'Иван',
      lastName: 'Петров',
      role: 'customer',
    });
    expect(res.accessToken).toBe('access-jwt');
    expect(res.refreshToken).toBe('refresh-jwt');
    expect(res.userId).toBeDefined();
  });

  it('конфликт: телефон занят', async () => {
    const { prisma, users } = mkPrisma();
    users.set('+79991112233', { id: 'u0', phone: '+79991112233' });
    const tokens = mkTokens();
    const svc = new AuthService(prisma, tokens, makeConfig() as any, new FixedClock(new Date()));
    await expect(
      svc.register({
        phone: '+79991112233',
        password: 'qwerty123',
        firstName: 'a',
        lastName: 'b',
        role: 'customer',
      }),
    ).rejects.toThrow(ConflictError);
  });

  it('хэширует пароль bcrypt-ом', async () => {
    const { prisma, users } = mkPrisma();
    const tokens = mkTokens();
    const svc = new AuthService(prisma, tokens, makeConfig() as any, new FixedClock(new Date()));
    await svc.register({
      phone: '+79991112233',
      password: 'qwerty123',
      firstName: 'a',
      lastName: 'b',
      role: 'customer',
    });
    const user = users.get('+79991112233');
    expect(user.passwordHash).not.toBe('qwerty123');
    await expect(bcrypt.compare('qwerty123', user.passwordHash)).resolves.toBe(true);
  });
});

describe('AuthService.login', () => {
  it('успешный логин с корректным паролем', async () => {
    const { prisma } = mkPrisma();
    const tokens = mkTokens();
    const svc = new AuthService(prisma, tokens, makeConfig() as any, new FixedClock(new Date()));
    await svc.register({
      phone: '+79991112233',
      password: 'qwerty123',
      firstName: 'a',
      lastName: 'b',
      role: 'customer',
    });
    const res = await svc.login({
      phone: '+79991112233',
      password: 'qwerty123',
      deviceId: 'd1',
      ip: '1.2.3.4',
    });
    expect(res.accessToken).toBe('access-jwt');
    expect(res.systemRole).toBe('customer');
  });

  it('неверный пароль → INVALID_CREDENTIALS', async () => {
    const { prisma } = mkPrisma();
    const tokens = mkTokens();
    const svc = new AuthService(prisma, tokens, makeConfig() as any, new FixedClock(new Date()));
    await svc.register({
      phone: '+79991112233',
      password: 'qwerty123',
      firstName: 'a',
      lastName: 'b',
      role: 'customer',
    });
    await expect(
      svc.login({ phone: '+79991112233', password: 'wrong', deviceId: 'd1', ip: '1.2.3.4' }),
    ).rejects.toThrow(AuthError);
  });

  it('несуществующий пользователь → INVALID_CREDENTIALS (не утечка данных)', async () => {
    const { prisma } = mkPrisma();
    const tokens = mkTokens();
    const svc = new AuthService(prisma, tokens, makeConfig() as any, new FixedClock(new Date()));
    await expect(
      svc.login({ phone: '+70000000000', password: 'x', deviceId: 'd1', ip: '1.2.3.4' }),
    ).rejects.toMatchObject({ response: { code: 'auth.invalid_credentials' } });
  });

  it('rate limit: после MAX неуспешных попыток — блок', async () => {
    const { prisma } = mkPrisma();
    const tokens = mkTokens();
    const svc = new AuthService(prisma, tokens, makeConfig() as any, new FixedClock(new Date()));
    await svc.register({
      phone: '+79991112233',
      password: 'qwerty123',
      firstName: 'a',
      lastName: 'b',
      role: 'customer',
    });
    // 3 неверных (MAX=3 в тестовом конфиге)
    for (let i = 0; i < 3; i++) {
      await expect(
        svc.login({ phone: '+79991112233', password: 'wrong', deviceId: 'd', ip: '1.2.3.4' }),
      ).rejects.toMatchObject({ response: { code: 'auth.invalid_credentials' } });
    }
    // 4-я попытка — даже с правильным паролем — блок
    await expect(
      svc.login({ phone: '+79991112233', password: 'qwerty123', deviceId: 'd', ip: '1.2.3.4' }),
    ).rejects.toMatchObject({ response: { code: 'auth.login_blocked' } });
  });
});

describe('AuthService.logout', () => {
  it('отзывает активную сессию', async () => {
    const { prisma } = mkPrisma();
    const tokens = mkTokens();
    const svc = new AuthService(prisma, tokens, makeConfig() as any, new FixedClock(new Date()));
    await svc.logout('some-refresh-token');
    expect(prisma.session.updateMany).toHaveBeenCalled();
  });

  it('идемпотентен при невалидном токене', async () => {
    const { prisma } = mkPrisma();
    const tokens = {
      ...mkTokens(),
      verifyRefresh: jest.fn().mockRejectedValue(new Error('invalid')),
    } as unknown as TokenService;
    const svc = new AuthService(prisma, tokens, makeConfig() as any, new FixedClock(new Date()));
    await expect(svc.logout('bad-token')).resolves.toBeUndefined();
  });
});
