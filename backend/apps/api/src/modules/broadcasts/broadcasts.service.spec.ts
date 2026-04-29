import { BroadcastsService } from './broadcasts.service';
import { FixedClock, InvalidInputError, PrismaService } from '@app/common';
import { AdminAuditService } from '../admin-audit/admin-audit.service';
import { NotificationsService } from '../notifications/notifications.service';

const mkPrisma = () => {
  const users = [
    { id: 'u-owner', roles: [{ role: 'customer' }], bannedAt: null },
    { id: 'u-foreman1', roles: [{ role: 'contractor' }], bannedAt: null },
    { id: 'u-foreman2', roles: [{ role: 'contractor' }], bannedAt: null },
    { id: 'u-master', roles: [{ role: 'master' }], bannedAt: null },
    { id: 'u-banned', roles: [{ role: 'customer' }], bannedAt: new Date() },
  ];
  // u-foreman1 — только iOS, u-foreman2 — только Android, u-master — оба, owner — без устройств.
  const deviceTokens = [
    { userId: 'u-foreman1', platform: 'ios' },
    { userId: 'u-foreman2', platform: 'android' },
    { userId: 'u-master', platform: 'ios' },
    { userId: 'u-master', platform: 'android' },
  ];
  const campaigns: any[] = [];
  const audit: any[] = [];
  const prisma: any = {
    user: {
      findMany: jest.fn(({ where }: any) => {
        return users.filter((u) => {
          if (where.id?.in && !where.id.in.includes(u.id)) return false;
          if (where.bannedAt === null && u.bannedAt !== null) return false;
          if (where.bannedAt?.not !== undefined && u.bannedAt === null) return false;
          if (where.roles?.some?.role?.in) {
            const has = u.roles.some((r: any) => where.roles.some.role.in.includes(r.role));
            if (!has) return false;
          }
          return true;
        });
      }),
    },
    broadcastCampaign: {
      create: jest.fn(({ data }: any) => {
        const c = { id: `c${campaigns.length + 1}`, ...data };
        campaigns.push(c);
        return c;
      }),
      update: jest.fn(({ where, data }: any) => {
        const c = campaigns.find((x) => x.id === where.id);
        Object.assign(c, data);
        return c;
      }),
      findMany: jest.fn(() => campaigns),
      findUnique: jest.fn(({ where }: any) => campaigns.find((c) => c.id === where.id) ?? null),
    },
    deviceToken: {
      findMany: jest.fn(({ where }: any) => {
        const userIds = where.userId.in as string[];
        const platform = where.platform as string;
        return deviceTokens.filter((t) => userIds.includes(t.userId) && t.platform === platform);
      }),
    },
    adminAuditLog: {
      create: jest.fn(({ data }: any) => {
        audit.push(data);
        return data;
      }),
    },
  };
  return { prisma: prisma as unknown as PrismaService, users, campaigns, audit };
};

const mkAudit = (prisma: PrismaService): AdminAuditService =>
  new AdminAuditService(prisma, new FixedClock(new Date()));

const mkNotifications = (): jest.Mocked<NotificationsService> => {
  return {
    dispatch: jest.fn().mockResolvedValue(undefined),
  } as unknown as jest.Mocked<NotificationsService>;
};

describe('BroadcastsService', () => {
  it('previewTargets — filter по role=customer возвращает 1 (banned не считается)', async () => {
    const state = mkPrisma();
    const svc = new BroadcastsService(
      state.prisma,
      new FixedClock(new Date()),
      mkAudit(state.prisma),
      mkNotifications(),
    );
    const r = await svc.previewTargets({ roles: ['customer' as any] });
    expect(r.count).toBe(1); // owner, banned не входит (bannedAt=null filter)
    expect(r.sampleUserIds).toContain('u-owner');
  });

  it('previewTargets — filter по role=contractor возвращает 2', async () => {
    const state = mkPrisma();
    const svc = new BroadcastsService(
      state.prisma,
      new FixedClock(new Date()),
      mkAudit(state.prisma),
      mkNotifications(),
    );
    const r = await svc.previewTargets({ roles: ['contractor' as any] });
    expect(r.count).toBe(2);
  });

  it('previewTargets — userIds override filter', async () => {
    const state = mkPrisma();
    const svc = new BroadcastsService(
      state.prisma,
      new FixedClock(new Date()),
      mkAudit(state.prisma),
      mkNotifications(),
    );
    const r = await svc.previewTargets({ userIds: ['u-master'] });
    expect(r.count).toBe(1);
    expect(r.sampleUserIds).toEqual(['u-master']);
  });

  it('previewTargets — platform=ios сужает только до пользователей с iOS-токенами', async () => {
    const state = mkPrisma();
    const svc = new BroadcastsService(
      state.prisma,
      new FixedClock(new Date()),
      mkAudit(state.prisma),
      mkNotifications(),
    );
    const r = await svc.previewTargets({
      roles: ['contractor' as any],
      platform: 'ios' as any,
    });
    expect(r.count).toBe(1);
    expect(r.sampleUserIds).toEqual(['u-foreman1']);
  });

  it('send — пустой target → InvalidInputError', async () => {
    const state = mkPrisma();
    const svc = new BroadcastsService(
      state.prisma,
      new FixedClock(new Date()),
      mkAudit(state.prisma),
      mkNotifications(),
    );
    await expect(
      svc.send('admin', {
        title: 't',
        body: 'b',
        filter: { userIds: ['u-nonexistent'] },
      }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('send — делегирует NotificationsService.dispatch с kind=admin_announcement', async () => {
    const state = mkPrisma();
    const notifications = mkNotifications();
    const svc = new BroadcastsService(
      state.prisma,
      new FixedClock(new Date()),
      mkAudit(state.prisma),
      notifications,
    );
    const r = await svc.send('admin', {
      title: 'Plan',
      body: 'Body',
      filter: { roles: ['contractor' as any] },
    });
    expect(r.status).toBe('sent');
    expect(r.targetCount).toBe(2);
    expect(notifications.dispatch).toHaveBeenCalledTimes(1);
    const call = notifications.dispatch.mock.calls[0][0];
    expect(call.kind).toBe('admin_announcement');
    expect(call.userIds).toHaveLength(2);
    expect(call.payload).toMatchObject({
      title: 'Plan',
      body: 'Body',
      source: 'admin_broadcast',
    });
    expect(state.audit.some((a) => a.action === 'broadcast.send')).toBe(true);
  });
});
