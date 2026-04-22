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
    const prisma = mkPrismaWithChat([]);
    const notifications = {
      dispatch: jest.fn().mockResolvedValue(undefined),
    } as unknown as NotificationsService;
    const router = new NotificationRouter(prisma, notifications);

    await router.fanOut({
      kind: 'material_request_created' as any,
      projectId: 'p1',
      actorId: 'u1',
      payload: { requestId: 'mr-42', addresseeId: 'u2' } as any,
    });

    // material_request_created использует projectMembers recipient resolver — prisma.project.findUnique вернёт null, значит пусто.
    // Для этого теста переопределим, чтобы получить проверку deepLink.
    const prisma2 = {
      ...prisma,
      project: {
        findUnique: jest.fn(async () => ({
          ownerId: 'u-owner',
          memberships: [{ userId: 'u-fm' }],
        })),
      },
    } as unknown as PrismaService;
    const router2 = new NotificationRouter(prisma2, notifications);
    (notifications.dispatch as jest.Mock).mockClear();

    await router2.fanOut({
      kind: 'material_request_created' as any,
      projectId: 'p1',
      actorId: 'u1',
      payload: { requestId: 'mr-42' },
    });

    const call = (notifications.dispatch as jest.Mock).mock.calls[0][0];
    expect(call.deepLink).toBe('repair://projects/p1/materials/mr-42');
  });
});
