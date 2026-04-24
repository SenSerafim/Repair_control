import { NotesService } from './notes.service';
import { FeedService } from '../feed/feed.service';
import { ForbiddenError, InvalidInputError, NotFoundError, PrismaService } from '@app/common';

type NoteRow = {
  id: string;
  scope: 'personal' | 'for_me' | 'stage';
  authorId: string;
  addresseeId: string | null;
  projectId: string;
  stageId: string | null;
  text: string;
  createdAt: Date;
  updatedAt: Date;
};

const mkPrisma = () => {
  const notes = new Map<string, NoteRow>();
  let seq = 0;

  const matches = (n: NoteRow, where: any): boolean => {
    if (where.projectId && n.projectId !== where.projectId) return false;
    if (where.stageId && n.stageId !== where.stageId) return false;
    if (where.text?.contains) {
      if (!n.text.toLowerCase().includes(where.text.contains.toLowerCase())) return false;
    }
    if (where.OR) {
      const orOk = where.OR.some((cond: any) => matches(n, cond));
      if (!orOk) return false;
    }
    if (where.scope && n.scope !== where.scope) return false;
    if (where.authorId && n.authorId !== where.authorId) return false;
    if (where.addresseeId && n.addresseeId !== where.addresseeId) return false;
    return true;
  };

  const prisma: any = {
    note: {
      create: jest.fn(({ data }: any) => {
        const now = new Date();
        const row: NoteRow = {
          id: `n${++seq}`,
          scope: data.scope,
          authorId: data.authorId,
          addresseeId: data.addresseeId ?? null,
          projectId: data.projectId,
          stageId: data.stageId ?? null,
          text: data.text,
          createdAt: now,
          updatedAt: now,
        };
        notes.set(row.id, row);
        return row;
      }),
      findUnique: jest.fn(({ where }: any) => notes.get(where.id) ?? null),
      findMany: jest.fn(({ where }: any) => [...notes.values()].filter((n) => matches(n, where))),
      update: jest.fn(({ where, data }: any) => {
        const n = notes.get(where.id);
        if (!n) throw new Error('not found');
        Object.assign(n, data);
        return n;
      }),
      delete: jest.fn(({ where }: any) => {
        notes.delete(where.id);
      }),
    },
    $transaction: jest.fn(async (fn: any) => fn(prisma)),
  };
  return { prisma: prisma as unknown as PrismaService, notes };
};

const mkFeed = (): FeedService => ({ emit: jest.fn().mockResolvedValue(undefined) }) as any;

describe('NotesService.create — валидация scope', () => {
  it('for_me требует addresseeId', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed());
    await expect(
      svc.create({ scope: 'for_me', text: 'x', projectId: 'p1', authorId: 'u1' }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('stage требует stageId', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed());
    await expect(
      svc.create({ scope: 'stage', text: 'x', projectId: 'p1', authorId: 'u1' }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('personal игнорирует addresseeId и stageId', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed());
    const n = await svc.create({
      scope: 'personal',
      text: 'для себя',
      projectId: 'p1',
      authorId: 'u1',
      addresseeId: 'ignored',
      stageId: 'ignored',
    });
    expect(n.addresseeId).toBeNull();
    expect(n.stageId).toBeNull();
  });

  it('пустой text отклоняется', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed());
    await expect(
      svc.create({ scope: 'personal', text: '   ', projectId: 'p1', authorId: 'u1' }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('эмитит note_created', async () => {
    const state = mkPrisma();
    const feed = mkFeed();
    const svc = new NotesService(state.prisma, feed);
    await svc.create({
      scope: 'personal',
      text: 'x',
      projectId: 'p1',
      authorId: 'u1',
    });
    expect(feed.emit).toHaveBeenCalledWith(expect.objectContaining({ kind: 'note_created' }));
  });
});

describe('NotesService.list — visibility по scope', () => {
  it('personal — видит только автор', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed());
    await svc.create({ scope: 'personal', text: 'u1-private', projectId: 'p1', authorId: 'u1' });
    await svc.create({ scope: 'personal', text: 'u2-private', projectId: 'p1', authorId: 'u2' });
    const res = await svc.list({ userId: 'u1', projectId: 'p1', scope: 'personal' });
    expect(res).toHaveLength(1);
    expect(res[0].text).toBe('u1-private');
  });

  it('for_me — видит автор и адресат', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed());
    await svc.create({
      scope: 'for_me',
      text: 'задача для u2',
      projectId: 'p1',
      authorId: 'u1',
      addresseeId: 'u2',
    });
    const asAuthor = await svc.list({ userId: 'u1', projectId: 'p1', scope: 'for_me' });
    const asAddressee = await svc.list({ userId: 'u2', projectId: 'p1', scope: 'for_me' });
    const asOther = await svc.list({ userId: 'u3', projectId: 'p1', scope: 'for_me' });
    expect(asAuthor).toHaveLength(1);
    expect(asAddressee).toHaveLength(1);
    expect(asOther).toHaveLength(0);
  });

  it('stage — видят все участники проекта', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed());
    await svc.create({
      scope: 'stage',
      text: 'этапная заметка',
      projectId: 'p1',
      stageId: 's1',
      authorId: 'u1',
    });
    const res = await svc.list({ userId: 'u2', projectId: 'p1', scope: 'stage' });
    expect(res).toHaveLength(1);
  });

  it('поиск по substring работает (case-insensitive)', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed());
    await svc.create({
      scope: 'personal',
      text: 'Купить Плитку',
      projectId: 'p1',
      authorId: 'u1',
    });
    const res = await svc.list({ userId: 'u1', projectId: 'p1', search: 'плитк' });
    expect(res).toHaveLength(1);
  });
});

describe('NotesService.update — author-only', () => {
  it('автор может редактировать', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed());
    const n = await svc.create({
      scope: 'personal',
      text: 'v1',
      projectId: 'p1',
      authorId: 'u1',
    });
    const upd = await svc.update(n.id, 'v2', 'u1');
    expect(upd.text).toBe('v2');
  });

  it('не автор — 403', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed());
    const n = await svc.create({
      scope: 'personal',
      text: 'v1',
      projectId: 'p1',
      authorId: 'u1',
    });
    await expect(svc.update(n.id, 'hacked', 'u2')).rejects.toThrow(ForbiddenError);
  });

  it('404 на несуществующую заметку', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed());
    await expect(svc.update('missing', 'x', 'u1')).rejects.toThrow(NotFoundError);
  });
});
