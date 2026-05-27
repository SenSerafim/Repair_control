import { NotificationRouter } from './notification-router';
import { NotificationsService } from './notifications.service';
import { PrismaService } from '@app/common';

describe('NotificationRouter.fanOut', () => {
  const mkPrismaWithChat = (participantIds: string[]) =>
    ({
      chatParticipant: {
        findMany: jest.fn(async () => participantIds.map((u) => ({ userId: u }))),
      },
      project: {
        findUnique: jest.fn(async () => null),
      },
      payment: {
        findUnique: jest.fn(async () => null),
      },
      exportJob: {
        findUnique: jest.fn(async () => null),
      },
      approval: {
        findUnique: jest.fn(async () => null),
      },
      selfPurchase: {
        findUnique: jest.fn(async () => null),
      },
      user: {
        findUnique: jest.fn(async () => null),
      },
      chatMessage: {
        findUnique: jest.fn(async () => null),
      },
      materialRequest: {
        findUnique: jest.fn(async () => null),
      },
      note: {
        findUnique: jest.fn(async () => null),
      },
      question: {
        findUnique: jest.fn(async () => null),
      },
      stage: {
        findUnique: jest.fn(async () => null),
      },
      step: {
        findUnique: jest.fn(async () => null),
      },
    }) as unknown as PrismaService;

  it('chat_message_sent — шлёт всем участникам чата кроме автора', async () => {
    const prisma = mkPrismaWithChat(['u1', 'u2', 'u3']);
    const notifications = {
      dispatch: jest.fn().mockResolvedValue(undefined),
    } as unknown as NotificationsService;
    const router = new NotificationRouter(prisma, notifications);

    await router.fanOut({
      kind: 'chat_message_sent' as any,
      projectId: 'p1',
      actorId: 'u1',
      payload: { chatId: 'c1', messageId: 'm1' },
    });

    expect(notifications.dispatch).toHaveBeenCalledWith(
      expect.objectContaining({
        userIds: expect.arrayContaining(['u2', 'u3']),
        kind: 'chat_message_new',
      }),
    );
    // u1 (автор) не должен быть в списке
    const call = (notifications.dispatch as jest.Mock).mock.calls[0][0];
    expect(call.userIds).not.toContain('u1');
  });

  it('approval_requested — шлёт только addresseeId из payload', async () => {
    const prisma = mkPrismaWithChat([]);
    const notifications = {
      dispatch: jest.fn().mockResolvedValue(undefined),
    } as unknown as NotificationsService;
    const router = new NotificationRouter(prisma, notifications);

    await router.fanOut({
      kind: 'approval_requested' as any,
      projectId: 'p1',
      actorId: 'u-foreman',
      payload: { addresseeId: 'u-customer', approvalId: 'a1' },
    });

    const call = (notifications.dispatch as jest.Mock).mock.calls[0][0];
    expect(call.userIds).toEqual(['u-customer']);
    expect(call.kind).toBe('approval_requested');
    expect(call.deepLink).toContain('approvals/a1');
  });

  it('unknown kind — не шлёт ничего', async () => {
    const prisma = mkPrismaWithChat([]);
    const notifications = {
      dispatch: jest.fn().mockResolvedValue(undefined),
    } as unknown as NotificationsService;
    const router = new NotificationRouter(prisma, notifications);

    await router.fanOut({
      kind: 'stage_deadline_recalculated' as any, // нет в MAPPINGS
      projectId: 'p1',
      actorId: 'u1',
      payload: {},
    });

    expect(notifications.dispatch).not.toHaveBeenCalled();
  });

  it('deepLink — содержит project + роль-независимую ссылку на ресурс', async () => {
    const prisma2 = {
      ...mkPrismaWithChat([]),
      project: {
        findUnique: jest.fn(async () => ({
          ownerId: 'u-owner',
          memberships: [{ userId: 'u-fm' }],
        })),
      },
    } as unknown as PrismaService;
    const notifications = {
      dispatch: jest.fn().mockResolvedValue(undefined),
    } as unknown as NotificationsService;
    const router2 = new NotificationRouter(prisma2, notifications);

    await router2.fanOut({
      kind: 'material_request_created' as any,
      projectId: 'p1',
      actorId: 'u1',
      payload: { requestId: 'mr-42' },
    });

    const call = (notifications.dispatch as jest.Mock).mock.calls[0][0];
    expect(call.deepLink).toBe('repair://projects/p1/materials/mr-42');
  });

  it('approval_resubmitted — поднимает addressee из БД и рендерит как approval_requested', async () => {
    const prisma = {
      ...mkPrismaWithChat([]),
      approval: {
        findUnique: jest.fn(async () => ({ addresseeId: 'u-customer', scope: 'plan' })),
      },
    } as unknown as PrismaService;
    const notifications = {
      dispatch: jest.fn().mockResolvedValue(undefined),
    } as unknown as NotificationsService;
    const router = new NotificationRouter(prisma, notifications);

    await router.fanOut({
      kind: 'approval_resubmitted' as any,
      projectId: 'p1',
      actorId: 'u-foreman',
      payload: { approvalId: 'a-1' },
    });

    const call = (notifications.dispatch as jest.Mock).mock.calls[0][0];
    expect(call.kind).toBe('approval_requested');
    expect(call.userIds).toEqual(['u-customer']);
    expect(call.payload.scope).toBe('plan');
  });

  it('selfpurchase_approved — шлёт автору заявки и проставляет scope', async () => {
    const prisma = {
      ...mkPrismaWithChat([]),
      selfPurchase: {
        findUnique: jest.fn(async () => ({ byUserId: 'u-foreman' })),
      },
    } as unknown as PrismaService;
    const notifications = {
      dispatch: jest.fn().mockResolvedValue(undefined),
    } as unknown as NotificationsService;
    const router = new NotificationRouter(prisma, notifications);

    await router.fanOut({
      kind: 'selfpurchase_approved' as any,
      projectId: 'p1',
      actorId: 'u-customer',
      payload: { selfPurchaseId: 'sp-1' },
    });

    const call = (notifications.dispatch as jest.Mock).mock.calls[0][0];
    expect(call.kind).toBe('approval_approved');
    expect(call.userIds).toEqual(['u-foreman']);
    expect(call.payload.scope).toBe('self_purchase');
  });

  it('tool_custody_changed — шлёт всем участникам проекта кроме actor-а, с holderName', async () => {
    const prisma = {
      ...mkPrismaWithChat([]),
      project: {
        findUnique: jest.fn(async () => ({
          ownerId: 'u-owner',
          memberships: [{ userId: 'u-actor' }, { userId: 'u-other' }],
        })),
      },
      user: {
        findUnique: jest.fn(async () => ({ firstName: 'Иван', lastName: 'Петров' })),
      },
    } as unknown as PrismaService;
    const notifications = {
      dispatch: jest.fn().mockResolvedValue(undefined),
    } as unknown as NotificationsService;
    const router = new NotificationRouter(prisma, notifications);

    await router.fanOut({
      kind: 'tool_custody_changed' as any,
      projectId: 'p1',
      actorId: 'u-actor',
      payload: { toolItemId: 't-1', toolName: 'Перфоратор', holderId: 'u-actor' },
    });

    const call = (notifications.dispatch as jest.Mock).mock.calls[0][0];
    expect(call.kind).toBe('tool_custody_changed');
    expect(call.userIds).toEqual(expect.arrayContaining(['u-owner', 'u-other']));
    expect(call.userIds).not.toContain('u-actor');
    expect(call.payload.holderName).toBe('Иван Петров');
    expect(call.deepLink).toBe('repair://projects/p1/tools/t-1');
  });

  it('plan_approved — шлёт всем участникам проекта с фиксированным scope=plan', async () => {
    const prisma = {
      ...mkPrismaWithChat([]),
      project: {
        findUnique: jest.fn(async () => ({
          ownerId: 'u-customer',
          memberships: [{ userId: 'u-foreman' }, { userId: 'u-master' }],
        })),
      },
    } as unknown as PrismaService;
    const notifications = {
      dispatch: jest.fn().mockResolvedValue(undefined),
    } as unknown as NotificationsService;
    const router = new NotificationRouter(prisma, notifications);

    await router.fanOut({
      kind: 'plan_approved' as any,
      projectId: 'p1',
      actorId: 'u-customer',
      payload: { approvalId: 'a-1' },
    });

    const call = (notifications.dispatch as jest.Mock).mock.calls[0][0];
    expect(call.kind).toBe('approval_approved');
    expect(call.userIds).toEqual(expect.arrayContaining(['u-foreman', 'u-master']));
    expect(call.userIds).not.toContain('u-customer');
    expect(call.payload.scope).toBe('plan');
  });
});
