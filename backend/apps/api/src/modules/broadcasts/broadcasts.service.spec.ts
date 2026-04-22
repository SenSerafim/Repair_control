import { BroadcastsService } from './broadcasts.service';
import { FixedClock, InvalidInputError, PrismaService } from '@app/common';
import { AdminAuditService } from '../admin-audit/admin-audit.service';

const mkPrisma = () => {
  const users = [
    { id: 'u-owner', roles: [{ role: 'customer' }], bannedAt: null },
    { id: 'u-foreman1', roles: [{ role: 'contractor' }], bannedAt: null },
    { id: 'u-foreman2', roles: [{ role: 'contractor' }], bannedAt: null },
    { id: 'u-master', roles: [{ role: 'master' }], bannedAt: null },
    { id: 'u-banned', roles: [{ role: 'customer' }], bannedAt: new Date() },
  ];
  const campaigns: any[] = [];
  const notifs: any[] = [];
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
    notificationLog: {
      create: jest.fn(({ data }: any) => {
        const n = { id: `n${notifs.length + 1}`, ...data };
        notifs.push(n);
        return n;
      }),
    },
    adminAuditLog: {
      create: jest.fn(({ data }: any) => {
        audit.push(data);
        return data;
      }),
    },
  };
  return { prisma: prisma as unknown as PrismaService, users, campaigns, notifs, audit };
};

const mkAudit = (prisma: PrismaService): AdminAuditService =>
  new AdminAuditService(prisma, new FixedClock(new Date()));

describe('BroadcastsService', () => {
  it('previewTargets — filter по role=customer возвращает 1 (banned не считается)', async () => {
    const state = mkPrisma();
    const svc = new BroadcastsService(
      state.prisma,
      new FixedClock(new Date()),
      mkAudit(state.prisma),
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
    );
    const r = await svc.previewTargets({ userIds: ['u-master'] });
    expect(r.count).toBe(1);
    expect(r.sampleUserIds).toEqual(['u-master']);
  });

  it('send — пустой target → InvalidInputError', async () => {
    const state = mkPrisma();
    const svc = new BroadcastsService(
      state.prisma,
      new FixedClock(new Date()),
      mkAudit(state.prisma),
    );
    await expect(
      svc.send('admin', {
        title: 't',
        body: 'b',
        filter: { userIds: ['u-nonexistent'] },
      }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('send — создаёт campaign и NotificationLog записи', async () => {
    const state = mkPrisma();
    const svc = new BroadcastsService(
      state.prisma,
      new FixedClock(new Date()),
      mkAudit(state.prisma),
    );
    const r = await svc.send('admin', {
      title: 'Plan',
      body: 'Body',
      filter: { roles: ['contractor' as any] },
    });
    expect(r.status).toBe('sent');
    expect(r.targetCount).toBe(2);
    expect(state.notifs.length).toBe(2);
    expect(state.audit.some((a) => a.action === 'broadcast.send')).toBe(true);
  });
});
