import { ChatsService } from './chats.service';
import { FeedService } from '../feed/feed.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { FixedClock, InvalidInputError, PrismaService } from '@app/common';

type Chat = {
  id: string;
  type: 'project' | 'stage' | 'personal' | 'group';
  projectId: string | null;
  stageId: string | null;
  title: string | null;
  visibleToCustomer: boolean;
  createdById: string;
  archivedAt: Date | null;
  createdAt: Date;
};
type Participant = {
  id: string;
  chatId: string;
  userId: string;
  leftAt: Date | null;
  joinedAt: Date;
};
type Membership = { userId: string; role: string; stageIds: string[] };
type Project = { id: string; ownerId: string; memberships: Membership[] };

const mkPrisma = () => {
  const chats = new Map<string, Chat>();
  const participants: Participant[] = [];
  const projects = new Map<string, Project>();
  let seq = 0;

  const prisma: any = {
    project: {
      findUnique: jest.fn(({ where, select }: any) => {
        const p = projects.get(where.id);
        if (!p) return null;
        // mock select. our select always has memberships with inner where: { userId: ... }
        if (select?.memberships?.where?.userId) {
          return {
            ownerId: p.ownerId,
            memberships: p.memberships.filter((m) => m.userId === select.memberships.where.userId),
          };
        }
        return { ownerId: p.ownerId, memberships: p.memberships };
      }),
    },
    membership: {
      findMany: jest.fn(({ where }: any) => {
        const p = projects.get(where.projectId);
        if (!p) return [];
        const ids = Array.isArray(where.userId?.in) ? where.userId.in : [where.userId];
        return p.memberships.filter((m) => ids.includes(m.userId));
      }),
    },
    chat: {
      findFirst: jest.fn(({ where, include }: any) => {
        for (const c of chats.values()) {
          if (where.type && c.type !== where.type) continue;
          if (where.projectId !== undefined && c.projectId !== where.projectId) continue;
          if (where.stageId !== undefined && c.stageId !== where.stageId) continue;
          if (where.archivedAt === null && c.archivedAt) continue;
          if (where.participants?.every) {
            // simplified: проверяем что все нужные юзеры входят
            const required: string[] = where.participants.every.userId.in;
            const cp = participants.filter((p) => p.chatId === c.id && p.leftAt === null);
            if (cp.length !== required.length) continue;
            if (!required.every((u) => cp.some((p) => p.userId === u))) continue;
          }
          if (include?.participants) {
            return { ...c, participants: participants.filter((p) => p.chatId === c.id) };
          }
          return c;
        }
        return null;
      }),
      findUnique: jest.fn(({ where, include }: any) => {
        const c = chats.get(where.id);
        if (!c) return null;
        if (include?.participants) {
          return {
            ...c,
            participants: participants.filter((p) => p.chatId === c.id),
          };
        }
        return c;
      }),
      findMany: jest.fn(({ where, include }: any) => {
        const list = [...chats.values()].filter((c) => {
          if (where.projectId && c.projectId !== where.projectId) return false;
          if (where.archivedAt === null && c.archivedAt) return false;
          if (where.participants?.some?.userId) {
            const cp = participants.filter(
              (p) =>
                p.chatId === c.id &&
                p.userId === where.participants.some.userId &&
                (where.participants.some.leftAt === null ? p.leftAt === null : true),
            );
            if (cp.length === 0) return false;
          }
          return true;
        });
        if (include?.participants) {
          return list.map((c) => ({
            ...c,
            participants: participants.filter((p) => p.chatId === c.id),
          }));
        }
        return list;
      }),
      create: jest.fn(({ data }: any) => {
        seq++;
        const c: Chat = {
          id: `c${seq}`,
          type: data.type,
          projectId: data.projectId ?? null,
          stageId: data.stageId ?? null,
          title: data.title ?? null,
          visibleToCustomer: data.visibleToCustomer ?? false,
          createdById: data.createdById,
          archivedAt: null,
          createdAt: new Date(),
        };
        chats.set(c.id, c);
        return c;
      }),
      update: jest.fn(({ where, data }: any) => {
        const c = chats.get(where.id);
        if (!c) throw new Error('not found');
        Object.assign(c, data);
        return c;
      }),
    },
    chatParticipant: {
      createMany: jest.fn(({ data }: any) => {
        for (const d of data) {
          participants.push({
            id: `p${participants.length + 1}`,
            chatId: d.chatId,
            userId: d.userId,
            leftAt: null,
            joinedAt: d.joinedAt ?? new Date(),
          });
        }
        return { count: data.length };
      }),
      create: jest.fn(({ data }: any) => {
        const p: Participant = {
          id: `p${participants.length + 1}`,
          chatId: data.chatId,
          userId: data.userId,
          leftAt: null,
          joinedAt: data.joinedAt ?? new Date(),
        };
        participants.push(p);
        return p;
      }),
      upsert: jest.fn(({ where, create, update: upd }: any) => {
        const existing = participants.find(
          (p) => p.chatId === where.chatId_userId.chatId && p.userId === where.chatId_userId.userId,
        );
        if (existing) {
          Object.assign(existing, upd);
          return existing;
        }
        participants.push({
          id: `p${participants.length + 1}`,
          chatId: create.chatId,
          userId: create.userId,
          leftAt: null,
          joinedAt: create.joinedAt ?? new Date(),
        });
        return participants[participants.length - 1];
      }),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };
  return { prisma: prisma as unknown as PrismaService, chats, participants, projects };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

describe('ChatsService', () => {
  it('ensureProjectChat — идемпотентен: повторный вызов возвращает тот же чат', async () => {
    const state = mkPrisma();
    state.projects.set('p1', {
      id: 'p1',
      ownerId: 'u-owner',
      memberships: [
        { userId: 'u-owner', role: 'customer', stageIds: [] },
        { userId: 'u-foreman', role: 'foreman', stageIds: [] },
      ],
    });
    const svc = new ChatsService(
      state.prisma,
      new FixedClock(new Date('2026-08-01T10:00:00Z')),
      mkFeed(),
      new EventEmitter2(),
    );

    const c1 = await svc.ensureProjectChat('p1', 'u-owner');
    const c2 = await svc.ensureProjectChat('p1', 'u-owner');
    expect(c1.id).toBe(c2.id);
    expect(state.chats.size).toBe(1);
    // Ownership + foreman добавлены как participants
    expect(state.participants.filter((p) => p.chatId === c1.id).length).toBeGreaterThanOrEqual(2);
  });

  it('createPersonal — с самим собой → InvalidInputError', async () => {
    const state = mkPrisma();
    const svc = new ChatsService(
      state.prisma,
      new FixedClock(new Date('2026-08-01T10:00:00Z')),
      mkFeed(),
      new EventEmitter2(),
    );
    await expect(svc.createPersonal('p1', 'u1', 'u1')).rejects.toThrow(InvalidInputError);
  });

  it('createPersonal — если target не член проекта и не owner → InvalidInputError', async () => {
    const state = mkPrisma();
    state.projects.set('p1', {
      id: 'p1',
      ownerId: 'u-owner',
      memberships: [{ userId: 'u-foreman', role: 'foreman', stageIds: [] }],
    });
    const svc = new ChatsService(
      state.prisma,
      new FixedClock(new Date('2026-08-01T10:00:00Z')),
      mkFeed(),
      new EventEmitter2(),
    );
    await expect(svc.createPersonal('p1', 'u-foreman', 'u-stranger')).rejects.toThrow(
      InvalidInputError,
    );
  });

  it('createPersonal — natural idempotency: повторный вызов возвращает тот же чат', async () => {
    const state = mkPrisma();
    state.projects.set('p1', {
      id: 'p1',
      ownerId: 'u-owner',
      memberships: [
        { userId: 'u-owner', role: 'customer', stageIds: [] },
        { userId: 'u-foreman', role: 'foreman', stageIds: [] },
      ],
    });
    const svc = new ChatsService(
      state.prisma,
      new FixedClock(new Date('2026-08-01T10:00:00Z')),
      mkFeed(),
      new EventEmitter2(),
    );
    const c1 = await svc.createPersonal('p1', 'u-owner', 'u-foreman');
    const c2 = await svc.createPersonal('p1', 'u-owner', 'u-foreman');
    expect(c1.id).toBe(c2.id);
  });

  it('leaveAllChats — soft-leave: leftAt=now(), чат не удаляется', async () => {
    const state = mkPrisma();
    state.projects.set('p1', {
      id: 'p1',
      ownerId: 'u-owner',
      memberships: [
        { userId: 'u-owner', role: 'customer', stageIds: [] },
        { userId: 'u-foreman', role: 'foreman', stageIds: [] },
      ],
    });
    const clock = new FixedClock(new Date('2026-08-01T10:00:00Z'));
    const svc = new ChatsService(state.prisma, clock, mkFeed(), new EventEmitter2());

    // Stub findMany для chatParticipant (у нас mock не полный)
    (state.prisma as any).chatParticipant.findMany = jest.fn(({ where }: any) =>
      state.participants.filter(
        (p) =>
          (!where.userId || p.userId === where.userId) &&
          (where.leftAt === null ? p.leftAt === null : true),
      ),
    );
    (state.prisma as any).chatParticipant.update = jest.fn(({ where, data }: any) => {
      const p = state.participants.find((x) => x.id === where.id);
      if (!p) throw new Error('not found');
      Object.assign(p, data);
      return p;
    });

    const chat = await svc.ensureProjectChat('p1', 'u-owner');
    expect(
      state.participants.filter((p) => p.chatId === chat.id && p.leftAt === null).length,
    ).toBeGreaterThan(0);

    await svc.leaveAllChats('u-foreman', 'p1');

    const fm = state.participants.find((p) => p.userId === 'u-foreman');
    expect(fm?.leftAt).toEqual(clock.now());
    // Чат остался
    expect(state.chats.size).toBe(1);
  });
});
