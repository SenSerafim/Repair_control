import { NotificationsService } from './notifications.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { InvalidInputError, PrismaService, SystemClock } from '@app/common';
import type { Queue } from 'bullmq';

type SettingRow = {
  userId: string;
  kind: string;
  pushEnabled: boolean;
};

const mkPrisma = () => {
  const settings = new Map<string, SettingRow>();
  const logs: any[] = [];

  const prisma: any = {
    notificationSetting: {
      findMany: jest.fn(({ where }: any) => {
        return [...settings.values()].filter(
          (s) =>
            (!where.userId ||
              (Array.isArray(where.userId?.in)
                ? where.userId.in.includes(s.userId)
                : where.userId === s.userId)) &&
            (!where.kind || s.kind === where.kind),
        );
      }),
      upsert: jest.fn(({ where, create, update }: any) => {
        const k = `${where.userId_kind.userId}:${where.userId_kind.kind}`;
        if (settings.has(k)) {
          const existing = settings.get(k)!;
          Object.assign(existing, update);
          return existing;
        }
        settings.set(k, { ...(create as SettingRow) });
        return settings.get(k);
      }),
    },
    notificationLog: {
      create: jest.fn(({ data }: any) => {
        logs.push(data);
        return { id: `log${logs.length}`, ...data };
      }),
    },
  };
  return { prisma: prisma as unknown as PrismaService, settings, logs };
};

const mkQueue = (): Queue => {
  const q: any = {
    add: jest.fn(async () => ({ id: 'job1' })),
  };
  return q as Queue;
};

describe('NotificationsService', () => {
  it('patchSetting — critical (approval_requested) с pushEnabled=false → 400', async () => {
    const state = mkPrisma();
    const svc = new NotificationsService(
      state.prisma,
      new SystemClock(),
      new EventEmitter2(),
      mkQueue(),
    );

    await expect(svc.patchSetting('u1', 'approval_requested' as any, false)).rejects.toThrow(
      InvalidInputError,
    );
  });

  it('patchSetting — high (chat_message_new) можно отключать', async () => {
    const state = mkPrisma();
    const svc = new NotificationsService(
      state.prisma,
      new SystemClock(),
      new EventEmitter2(),
      mkQueue(),
    );

    await svc.patchSetting('u1', 'chat_message_new' as any, false);

    const settings = await svc.getSettings('u1');
    const chat = settings.find((s) => s.kind === 'chat_message_new');
    expect(chat?.pushEnabled).toBe(false);
    // Critical не изменились — остались true
    const approval = settings.find((s) => s.kind === 'approval_requested');
    expect(approval?.pushEnabled).toBe(true);
  });

  it('getSettings — все kinds возвращаются с priority и critical флагом', async () => {
    const state = mkPrisma();
    const svc = new NotificationsService(
      state.prisma,
      new SystemClock(),
      new EventEmitter2(),
      mkQueue(),
    );

    const settings = await svc.getSettings('u1');
    // Проверяем, что пришли и critical и high типы
    const criticals = settings.filter((s) => s.critical);
    const highs = settings.filter((s) => !s.critical && s.priority === 'high');
    expect(criticals.length).toBeGreaterThan(5);
    expect(highs.length).toBeGreaterThan(0);
    // Дефолт — всё включено
    expect(settings.every((s) => s.pushEnabled)).toBe(true);
  });

  it('dispatch — critical пуш летит всем, даже с выключенной настройкой', async () => {
    const state = mkPrisma();
    const events = new EventEmitter2();
    const queue = mkQueue();
    const svc = new NotificationsService(state.prisma, new SystemClock(), events, queue);

    // Эмулируем: u1 отключил chat_message_new (high) — но мы шлём approval_requested (critical)
    state.settings.set('u1:chat_message_new', {
      userId: 'u1',
      kind: 'chat_message_new',
      pushEnabled: false,
    });

    await svc.dispatch({
      userIds: ['u1', 'u2'],
      kind: 'approval_requested' as any,
      projectId: 'p1',
      payload: { scopeRu: 'План работ' },
    });

    expect((queue.add as jest.Mock).mock.calls.length).toBe(2);
    const jobs = (queue.add as jest.Mock).mock.calls.map((c) => c[1]);
    expect(jobs[0].kind).toBe('approval_requested');
    expect(jobs[0].priority).toBe('critical');
  });

  it('dispatch — high пуш не летит тем, кто отключил', async () => {
    const state = mkPrisma();
    const events = new EventEmitter2();
    const queue = mkQueue();
    const svc = new NotificationsService(state.prisma, new SystemClock(), events, queue);

    state.settings.set('u1:chat_message_new', {
      userId: 'u1',
      kind: 'chat_message_new',
      pushEnabled: false,
    });

    await svc.dispatch({
      userIds: ['u1', 'u2'],
      kind: 'chat_message_new' as any,
      projectId: 'p1',
      payload: { preview: 'hello' },
    });

    // Только u2 получил (u1 отключён)
    expect((queue.add as jest.Mock).mock.calls.length).toBe(1);
    expect((queue.add as jest.Mock).mock.calls[0][1].userId).toBe('u2');
  });
});
