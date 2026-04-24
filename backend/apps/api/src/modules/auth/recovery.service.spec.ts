import { RecoveryService } from './recovery.service';
import { SmsService } from './sms.service';
import { AuthError, FixedClock, PrismaService } from '@app/common';

const makeConfig = () => ({
  get: (k: string, def?: any) => {
    if (k === 'RECOVERY_MAX_ATTEMPTS') return 3;
    if (k === 'RECOVERY_BLOCK_SECONDS') return 300;
    if (k === 'BCRYPT_COST') return 4;
    return def;
  },
});

const mkPrisma = () => {
  const users = new Map<string, any>();
  const attempts: any[] = [];
  const prisma: any = {
    user: {
      findUnique: jest.fn(({ where }: any) => {
        if (where.phone) return users.get(where.phone) ?? null;
        if (where.id) return [...users.values()].find((u) => u.id === where.id) ?? null;
        return null;
      }),
      update: jest.fn(({ where, data }: any) => {
        const u = [...users.values()].find((x) => x.id === where.id);
        if (!u) throw new Error(`mock: no user with id ${where.id}`);
        Object.assign(u, data);
        return u;
      }),
    },
    recoveryAttempt: {
      create: jest.fn(({ data }: any) => {
        const r = { id: `a${attempts.length}`, ...data, createdAt: new Date() };
        attempts.push(r);
        return r;
      }),
      findFirst: jest.fn(({ where, orderBy }: any) => {
        const list = attempts.filter((a) => a.userId === where.userId && !a.isUsed);
        return orderBy?.createdAt === 'desc' ? list[list.length - 1] : list[0];
      }),
      update: jest.fn(({ where, data }: any) => {
        const a = attempts.find((x) => x.id === where.id);
        Object.assign(a, data);
        return a;
      }),
      updateMany: jest.fn(({ where, data }: any) => {
        const hits = attempts.filter((a) => a.userId === where.userId && !a.isUsed);
        hits.forEach((h) => Object.assign(h, data));
        return { count: hits.length };
      }),
    },
    session: {
      updateMany: jest.fn(async () => ({ count: 0 })),
    },
    $transaction: jest.fn(async (ops: any) => {
      if (typeof ops === 'function') return ops(prisma);
      return Promise.all(ops);
    }),
  };
  return { prisma: prisma as unknown as PrismaService, users, attempts };
};

describe('RecoveryService', () => {
  const now = new Date('2026-06-01T10:00:00Z');

  it('sendCode: единый ответ даже если номер не найден (защита от энумерации)', async () => {
    const { prisma } = mkPrisma();
    const sms = { sendRecoveryCode: jest.fn() } as unknown as SmsService;
    const svc = new RecoveryService(prisma, sms, makeConfig() as any, new FixedClock(now));

    const res = await svc.sendCode('+79999999999');
    expect(res.sent).toBe(true);
    expect(sms.sendRecoveryCode).not.toHaveBeenCalled();
  });

  it('sendCode: создаёт запись и отправляет SMS, если пользователь есть', async () => {
    const { prisma, users } = mkPrisma();
    users.set('+79991112233', { id: 'u1', phone: '+79991112233' });
    const sms = { sendRecoveryCode: jest.fn() } as unknown as SmsService;
    const svc = new RecoveryService(prisma, sms, makeConfig() as any, new FixedClock(now));

    await svc.sendCode('+79991112233');
    expect(sms.sendRecoveryCode).toHaveBeenCalledWith(
      '+79991112233',
      expect.stringMatching(/^\d{6}$/),
    );
  });

  it('verifyCode: 3 неверные попытки → блокировка на 5 минут', async () => {
    const { prisma, users } = mkPrisma();
    users.set('+79991112233', { id: 'u1', phone: '+79991112233' });
    const sms = { sendRecoveryCode: jest.fn() } as unknown as SmsService;
    const clock = new FixedClock(now);
    const svc = new RecoveryService(prisma, sms, makeConfig() as any, clock);

    await svc.sendCode('+79991112233');
    const code = (sms.sendRecoveryCode as jest.Mock).mock.calls[0][1];

    // 2 неверные — не блок
    await expect(svc.verifyCode('+79991112233', '000000')).rejects.toThrow(AuthError);
    await expect(svc.verifyCode('+79991112233', '000000')).rejects.toThrow(AuthError);

    // 3-я неверная — блок
    await expect(svc.verifyCode('+79991112233', '000000')).rejects.toThrow(AuthError);

    // Любая дальнейшая (включая правильный код) — уже блок
    await expect(svc.verifyCode('+79991112233', code)).rejects.toMatchObject({
      response: { code: 'auth.recovery_blocked' },
    });

    // После снятия блока (перевод часов на +6 мин) — сверяем, что код всё ещё принимается.
    // Но по умолчанию attempt.code не меняется, так что корректный код пройдёт.
    clock.advanceMs(6 * 60 * 1000);
    // После таймаута блокировки — код верный, должен пройти
    await expect(svc.verifyCode('+79991112233', code)).resolves.toBeUndefined();
  });

  it('verifyCode: истёкший код → RECOVERY_EXPIRED', async () => {
    const { prisma, users } = mkPrisma();
    users.set('+79991112233', { id: 'u1', phone: '+79991112233' });
    const sms = { sendRecoveryCode: jest.fn() } as unknown as SmsService;
    const clock = new FixedClock(now);
    const svc = new RecoveryService(prisma, sms, makeConfig() as any, clock);

    await svc.sendCode('+79991112233');
    const code = (sms.sendRecoveryCode as jest.Mock).mock.calls[0][1];

    clock.advanceMs(11 * 60 * 1000); // 11 минут — код жив 10

    await expect(svc.verifyCode('+79991112233', code)).rejects.toMatchObject({
      response: { code: 'auth.recovery_expired' },
    });
  });

  it('resetPassword: отзывает все активные сессии после успеха', async () => {
    const { prisma, users } = mkPrisma();
    users.set('+79991112233', { id: 'u1', phone: '+79991112233', passwordHash: 'old' });
    const sms = { sendRecoveryCode: jest.fn() } as unknown as SmsService;
    const clock = new FixedClock(now);
    const svc = new RecoveryService(prisma, sms, makeConfig() as any, clock);

    await svc.sendCode('+79991112233');
    const code = (sms.sendRecoveryCode as jest.Mock).mock.calls[0][1];

    await svc.resetPassword('+79991112233', code, 'newStrongPass123');

    expect(prisma.session.updateMany).toHaveBeenCalledWith({
      where: { userId: 'u1', revokedAt: null },
      data: { revokedAt: now },
    });
  });
});
