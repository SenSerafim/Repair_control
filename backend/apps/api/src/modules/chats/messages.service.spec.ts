import { MessagesService } from './messages.service';
import { ChatsService } from './chats.service';
import { FeedService } from '../feed/feed.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  ConflictError,
  FixedClock,
  ForbiddenError,
  InvalidInputError,
  PrismaService,
} from '@app/common';

type Msg = {
  id: string;
  chatId: string;
  authorId: string;
  text: string | null;
  attachmentKeys: string[];
  forwardedFromId: string | null;
  editedAt: Date | null;
  deletedAt: Date | null;
  createdAt: Date;
};

type Participant = { id: string; chatId: string; userId: string; leftAt: Date | null };
type Chat = { id: string; projectId: string | null; archivedAt: Date | null; createdById: string };

const mkPrisma = (
  options: {
    messages?: Msg[];
    participants?: Participant[];
    chats?: Chat[];
  } = {},
) => {
  const messages = new Map<string, Msg>((options.messages ?? []).map((m) => [m.id, m]));
  const participants = (options.participants ?? []).map((p) => ({ ...p }));
  const chats = new Map<string, Chat>((options.chats ?? []).map((c) => [c.id, c]));
  let seq = messages.size;

  const prisma: any = {
    chatMessage: {
      findUnique: jest.fn(({ where }: any) => messages.get(where.id) ?? null),
      findMany: jest.fn(({ where, take }: any) => {
        const list = [...messages.values()].filter((m) => m.chatId === where.chatId);
        list.sort((a, b) => {
          const t = b.createdAt.getTime() - a.createdAt.getTime();
          return t !== 0 ? t : b.id > a.id ? 1 : -1;
        });
        return list.slice(0, take ?? 50);
      }),
      create: jest.fn(({ data }: any) => {
        seq++;
        const m: Msg = {
          id: `m${seq}`,
          chatId: data.chatId,
          authorId: data.authorId,
          text: data.text ?? null,
          attachmentKeys: data.attachmentKeys ?? [],
          forwardedFromId: data.forwardedFromId ?? null,
          editedAt: null,
          deletedAt: null,
          createdAt: data.createdAt ?? new Date(),
        };
        messages.set(m.id, m);
        return m;
      }),
      update: jest.fn(({ where, data }: any) => {
        const m = messages.get(where.id);
        if (!m) throw new Error('not found');
        Object.assign(m, data);
        return m;
      }),
    },
    chatParticipant: {
      findUnique: jest.fn(
        ({ where }: any) =>
          participants.find(
            (p) =>
              p.chatId === where.chatId_userId.chatId && p.userId === where.chatId_userId.userId,
          ) ?? null,
      ),
    },
    chat: {
      findUnique: jest.fn(({ where }: any) => chats.get(where.id) ?? null),
    },
    project: {
      findUnique: jest.fn(() => null),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };
  return { prisma: prisma as unknown as PrismaService, messages, participants, chats };
};

describe('MessagesService', () => {
  const chatId = 'c1';
  const authorId = 'u1';
  const strangerId = 'u2';

  const mkChatsService = (p: PrismaService, clock: FixedClock): ChatsService => {
    return new ChatsService(
      p,
      clock,
      { emit: jest.fn() } as unknown as FeedService,
      new EventEmitter2(),
    );
  };

  const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

  it('create — пустое body без text и attachments → InvalidInputError', async () => {
    const clock = new FixedClock(new Date('2026-08-01T10:00:00Z'));
    const state = mkPrisma({
      chats: [{ id: chatId, projectId: 'p1', archivedAt: null, createdById: authorId }],
      participants: [{ id: 'pp1', chatId, userId: authorId, leftAt: null }],
    });
    const chats = mkChatsService(state.prisma, clock);
    const svc = new MessagesService(state.prisma, clock, mkFeed(), new EventEmitter2(), chats);

    await expect(svc.create(chatId, authorId, {})).rejects.toThrow(InvalidInputError);
  });

  it('create — non-participant → ForbiddenError (внутри assertActiveParticipant)', async () => {
    const clock = new FixedClock(new Date('2026-08-01T10:00:00Z'));
    const state = mkPrisma({
      chats: [{ id: chatId, projectId: 'p1', archivedAt: null, createdById: authorId }],
      participants: [], // stranger not added
    });
    const chats = mkChatsService(state.prisma, clock);
    const svc = new MessagesService(state.prisma, clock, mkFeed(), new EventEmitter2(), chats);

    await expect(svc.create(chatId, strangerId, { text: 'hi' })).rejects.toThrow(ForbiddenError);
  });

  it('create — персистит message и эмитит chat.message.sent', async () => {
    const clock = new FixedClock(new Date('2026-08-01T10:00:00Z'));
    const state = mkPrisma({
      chats: [{ id: chatId, projectId: 'p1', archivedAt: null, createdById: authorId }],
      participants: [{ id: 'pp1', chatId, userId: authorId, leftAt: null }],
    });
    const chats = mkChatsService(state.prisma, clock);
    const events = new EventEmitter2();
    const listener = jest.fn();
    events.on('chat.message.sent', listener);
    const svc = new MessagesService(state.prisma, clock, mkFeed(), events, chats);

    const m = await svc.create(chatId, authorId, { text: 'hi' });
    expect(m.text).toBe('hi');
    expect(state.messages.size).toBe(1);
    expect(listener).toHaveBeenCalledWith(expect.objectContaining({ chatId }));
  });

  it('edit — только автор', async () => {
    const clock = new FixedClock(new Date('2026-08-01T10:00:00Z'));
    const existing: Msg = {
      id: 'm1',
      chatId,
      authorId,
      text: 'original',
      attachmentKeys: [],
      forwardedFromId: null,
      editedAt: null,
      deletedAt: null,
      createdAt: clock.now(),
    };
    const state = mkPrisma({
      chats: [{ id: chatId, projectId: 'p1', archivedAt: null, createdById: authorId }],
      participants: [{ id: 'pp1', chatId, userId: authorId, leftAt: null }],
      messages: [existing],
    });
    const chats = mkChatsService(state.prisma, clock);
    const svc = new MessagesService(state.prisma, clock, mkFeed(), new EventEmitter2(), chats);

    await expect(svc.edit('m1', strangerId, 'hack')).rejects.toThrow(ForbiddenError);
    const edited = await svc.edit('m1', authorId, 'edited');
    expect(edited.text).toBe('edited');
    expect(edited.editedAt).not.toBeNull();
  });

  it('edit — после 15 минут → 409', async () => {
    const clock = new FixedClock(new Date('2026-08-01T10:00:00Z'));
    const existing: Msg = {
      id: 'm1',
      chatId,
      authorId,
      text: 'original',
      attachmentKeys: [],
      forwardedFromId: null,
      editedAt: null,
      deletedAt: null,
      createdAt: clock.now(),
    };
    const state = mkPrisma({
      chats: [{ id: chatId, projectId: 'p1', archivedAt: null, createdById: authorId }],
      participants: [{ id: 'pp1', chatId, userId: authorId, leftAt: null }],
      messages: [existing],
    });
    const chats = mkChatsService(state.prisma, clock);
    const svc = new MessagesService(state.prisma, clock, mkFeed(), new EventEmitter2(), chats);

    clock.advanceMs(16 * 60 * 1000);
    await expect(svc.edit('m1', authorId, 'late')).rejects.toThrow(ConflictError);
  });

  it('softDelete — текст заменяется на "(сообщение удалено)", вложения стираются', async () => {
    const clock = new FixedClock(new Date('2026-08-01T10:00:00Z'));
    const existing: Msg = {
      id: 'm1',
      chatId,
      authorId,
      text: 'secret',
      attachmentKeys: ['k1', 'k2'],
      forwardedFromId: null,
      editedAt: null,
      deletedAt: null,
      createdAt: clock.now(),
    };
    const state = mkPrisma({
      chats: [{ id: chatId, projectId: 'p1', archivedAt: null, createdById: authorId }],
      participants: [{ id: 'pp1', chatId, userId: authorId, leftAt: null }],
      messages: [existing],
    });
    const chats = mkChatsService(state.prisma, clock);
    const svc = new MessagesService(state.prisma, clock, mkFeed(), new EventEmitter2(), chats);

    await svc.softDelete('m1', authorId);
    const after = state.messages.get('m1')!;
    expect(after.deletedAt).not.toBeNull();
    expect(after.text).toBe('(сообщение удалено)');
    expect(after.attachmentKeys).toEqual([]);
  });

  it('softDelete — чужой не может (не автор/не creator чата) → 403', async () => {
    const clock = new FixedClock(new Date('2026-08-01T10:00:00Z'));
    const existing: Msg = {
      id: 'm1',
      chatId,
      authorId,
      text: 'mine',
      attachmentKeys: [],
      forwardedFromId: null,
      editedAt: null,
      deletedAt: null,
      createdAt: clock.now(),
    };
    const state = mkPrisma({
      chats: [{ id: chatId, projectId: 'p1', archivedAt: null, createdById: authorId }],
      participants: [{ id: 'pp1', chatId, userId: authorId, leftAt: null }],
      messages: [existing],
    });
    const chats = mkChatsService(state.prisma, clock);
    const svc = new MessagesService(state.prisma, clock, mkFeed(), new EventEmitter2(), chats);

    await expect(svc.softDelete('m1', strangerId)).rejects.toThrow(ForbiddenError);
  });

  it('list — курсорная пагинация: 3 сообщения, limit=2, далее по cursor', async () => {
    const clock = new FixedClock(new Date('2026-08-01T10:00:00Z'));
    const msgs: Msg[] = [1, 2, 3].map((n) => ({
      id: `m${n}`,
      chatId,
      authorId,
      text: `#${n}`,
      attachmentKeys: [],
      forwardedFromId: null,
      editedAt: null,
      deletedAt: null,
      createdAt: new Date(clock.now().getTime() + n * 1000),
    }));
    const state = mkPrisma({
      chats: [{ id: chatId, projectId: 'p1', archivedAt: null, createdById: authorId }],
      participants: [{ id: 'pp1', chatId, userId: authorId, leftAt: null }],
      messages: msgs,
    });
    const chats = mkChatsService(state.prisma, clock);
    const svc = new MessagesService(state.prisma, clock, mkFeed(), new EventEmitter2(), chats);

    const page1 = await svc.list(chatId, authorId, { limit: 2 });
    expect(page1.items.map((m) => m.id)).toEqual(['m3', 'm2']);
    expect(page1.nextCursor).toBeTruthy();
    // Note: mock не учитывает cursor-предикат точно; проверяем, что cursor генерится
  });
});
