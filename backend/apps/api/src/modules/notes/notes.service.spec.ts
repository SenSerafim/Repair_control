import { NotesService } from './notes.service';
import { FeedService } from '../feed/feed.service';
import { ForbiddenError, InvalidInputError, NotFoundError, PrismaService } from '@app/common';
import { FilesService } from '@app/files';

type NoteRow = {
  id: string;
  scope: 'personal' | 'for_me' | 'stage' | 'team_broadcast';
  kind: 'text' | 'audio';
  authorId: string;
  addresseeId: string | null;
  projectId: string;
  stageId: string | null;
  text: string | null;
  audioKey: string | null;
  audioMimeType: string | null;
  audioDurationMs: number | null;
  transcript: string | null;
  transcriptStatus: 'pending' | 'done' | 'failed' | null;
  transcriptProvider: string | null;
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
      if (!(n.text ?? '').toLowerCase().includes(where.text.contains.toLowerCase())) return false;
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
          kind: data.kind ?? 'text',
          authorId: data.authorId,
          addresseeId: data.addresseeId ?? null,
          projectId: data.projectId,
          stageId: data.stageId ?? null,
          text: data.text ?? null,
          audioKey: data.audioKey ?? null,
          audioMimeType: data.audioMimeType ?? null,
          audioDurationMs: data.audioDurationMs ?? null,
          transcript: null,
          transcriptStatus: null,
          transcriptProvider: null,
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

const mkFiles = (): FilesService =>
  ({
    createPresignedDownload: jest.fn().mockImplementation(async (key: string) => ({
      url: `https://s3/${key}?sig=x`,
      expiresAt: new Date(),
    })),
    removeObject: jest.fn().mockResolvedValue(undefined),
  }) as any;

describe('NotesService.create — валидация scope/kind', () => {
  it('for_me требует addresseeId', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
    await expect(
      svc.create({ scope: 'for_me', text: 'x', projectId: 'p1', authorId: 'u1' }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('stage требует stageId', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
    await expect(
      svc.create({ scope: 'stage', text: 'x', projectId: 'p1', authorId: 'u1' }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('personal игнорирует addresseeId и stageId', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
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

  it('пустой text у text-заметки отклоняется', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
    await expect(
      svc.create({ scope: 'personal', text: '   ', projectId: 'p1', authorId: 'u1' }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('audio без audioKey отклоняется', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
    await expect(
      svc.create({
        scope: 'personal',
        kind: 'audio',
        audioMimeType: 'audio/m4a',
        projectId: 'p1',
        authorId: 'u1',
      }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('audio без audioMimeType отклоняется', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
    await expect(
      svc.create({
        scope: 'personal',
        kind: 'audio',
        audioKey: 'notes/audio/abc.m4a',
        projectId: 'p1',
        authorId: 'u1',
      }),
    ).rejects.toThrow(InvalidInputError);
  });

  it('audio с обоими полями — сохраняется и enrich даёт audioUrl', async () => {
    const state = mkPrisma();
    const files = mkFiles();
    const svc = new NotesService(state.prisma, mkFeed(), files);
    const n = await svc.create({
      scope: 'personal',
      kind: 'audio',
      audioKey: 'notes/audio/abc.m4a',
      audioMimeType: 'audio/m4a',
      audioDurationMs: 12345,
      projectId: 'p1',
      authorId: 'u1',
    });
    expect(n.kind).toBe('audio');
    expect(n.audioKey).toBe('notes/audio/abc.m4a');
    expect(n.audioDurationMs).toBe(12345);
    expect(n.audioUrl).toContain('https://s3/notes/audio/abc.m4a');
    expect(files.createPresignedDownload).toHaveBeenCalledWith('notes/audio/abc.m4a');
  });

  it('text-заметка не вызывает presign-download', async () => {
    const state = mkPrisma();
    const files = mkFiles();
    const svc = new NotesService(state.prisma, mkFeed(), files);
    const n = await svc.create({
      scope: 'personal',
      text: 'обычный текст',
      projectId: 'p1',
      authorId: 'u1',
    });
    expect(n.kind).toBe('text');
    expect(n.audioUrl).toBeNull();
    expect(files.createPresignedDownload).not.toHaveBeenCalled();
  });

  it('эмитит note_created c noteKind в payload', async () => {
    const state = mkPrisma();
    const feed = mkFeed();
    const svc = new NotesService(state.prisma, feed, mkFiles());
    await svc.create({
      scope: 'personal',
      kind: 'audio',
      audioKey: 'notes/audio/abc.m4a',
      audioMimeType: 'audio/m4a',
      projectId: 'p1',
      authorId: 'u1',
    });
    expect(feed.emit).toHaveBeenCalledWith(
      expect.objectContaining({
        kind: 'note_created',
        payload: expect.objectContaining({ noteKind: 'audio', scope: 'personal' }),
      }),
    );
  });

  it('feed-payload содержит addresseeId для scope=for_me (push → addressee)', async () => {
    const state = mkPrisma();
    const feed = mkFeed();
    const svc = new NotesService(state.prisma, feed, mkFiles());
    await svc.create({
      scope: 'for_me',
      text: 'для u2',
      projectId: 'p1',
      authorId: 'u1',
      addresseeId: 'u2',
    });
    expect(feed.emit).toHaveBeenCalledWith(
      expect.objectContaining({
        kind: 'note_created',
        payload: expect.objectContaining({ addresseeId: 'u2', scope: 'for_me' }),
      }),
    );
  });

  it('team_broadcast — без addressee/stage, проходит валидацию', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
    const n = await svc.create({
      scope: 'team_broadcast',
      text: 'привет команда',
      projectId: 'p1',
      authorId: 'u1',
    });
    expect(n.scope).toBe('team_broadcast');
    expect(n.addresseeId).toBeNull();
    expect(n.stageId).toBeNull();
  });
});

describe('NotesService.list — visibility и фильтры (E11 §11.5)', () => {
  it('personal — видит только автор', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
    await svc.create({ scope: 'personal', text: 'u1-private', projectId: 'p1', authorId: 'u1' });
    await svc.create({ scope: 'personal', text: 'u2-private', projectId: 'p1', authorId: 'u2' });
    const res = await svc.list({ userId: 'u1', projectId: 'p1', scope: 'personal' });
    expect(res).toHaveLength(1);
    expect(res[0].text).toBe('u1-private');
  });

  it('for_me — видит автор и адресат', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
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
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
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

  it('team_broadcast — видна любому участнику проекта (П1.10/П2.19)', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
    await svc.create({
      scope: 'team_broadcast',
      text: 'на стенд',
      projectId: 'p1',
      authorId: 'u1',
    });
    const res = await svc.list({ userId: 'u9', projectId: 'p1', scope: 'team_broadcast' });
    expect(res).toHaveLength(1);
    expect(res[0].scope).toBe('team_broadcast');
  });

  it('list без scope — отдаёт все 4 типа автору', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
    await svc.create({ scope: 'personal', text: 'p', projectId: 'p1', authorId: 'u1' });
    await svc.create({
      scope: 'for_me',
      text: 'fm',
      projectId: 'p1',
      authorId: 'u1',
      addresseeId: 'u2',
    });
    await svc.create({
      scope: 'stage',
      text: 's',
      projectId: 'p1',
      stageId: 's1',
      authorId: 'u1',
    });
    await svc.create({ scope: 'team_broadcast', text: 'tb', projectId: 'p1', authorId: 'u1' });
    const res = await svc.list({ userId: 'u1', projectId: 'p1' });
    const scopes = res.map((n) => n.scope).sort();
    expect(scopes).toEqual(['for_me', 'personal', 'stage', 'team_broadcast']);
  });

  it('filter=mine — только заметки, где автор — текущий пользователь', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
    await svc.create({ scope: 'team_broadcast', text: 'u1-tb', projectId: 'p1', authorId: 'u1' });
    await svc.create({ scope: 'team_broadcast', text: 'u2-tb', projectId: 'p1', authorId: 'u2' });
    await svc.create({ scope: 'personal', text: 'u1-pers', projectId: 'p1', authorId: 'u1' });
    const res = await svc.list({ userId: 'u1', projectId: 'p1', filter: 'mine' });
    expect(res.every((n) => n.authorId === 'u1')).toBe(true);
    const texts = res.map((n) => n.text).sort();
    expect(texts).toEqual(['u1-pers', 'u1-tb']);
  });

  it('filter=team — только team_broadcast (доступны всем)', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
    await svc.create({ scope: 'team_broadcast', text: 'tb', projectId: 'p1', authorId: 'u1' });
    await svc.create({ scope: 'personal', text: 'priv', projectId: 'p1', authorId: 'u1' });
    const res = await svc.list({ userId: 'u9', projectId: 'p1', filter: 'team' });
    expect(res).toHaveLength(1);
    expect(res[0].scope).toBe('team_broadcast');
  });

  it('поиск по substring работает (case-insensitive)', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
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
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
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
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
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
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
    await expect(svc.update('missing', 'x', 'u1')).rejects.toThrow(NotFoundError);
  });

  it('audio-заметка — caption можно очистить пустой строкой', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
    const n = await svc.create({
      scope: 'personal',
      kind: 'audio',
      text: 'caption v1',
      audioKey: 'notes/audio/x.m4a',
      audioMimeType: 'audio/m4a',
      projectId: 'p1',
      authorId: 'u1',
    });
    const upd = await svc.update(n.id, '', 'u1');
    expect(upd.text).toBeNull();
  });

  it('text-заметка — пустой текст отклоняется', async () => {
    const state = mkPrisma();
    const svc = new NotesService(state.prisma, mkFeed(), mkFiles());
    const n = await svc.create({
      scope: 'personal',
      text: 'v1',
      projectId: 'p1',
      authorId: 'u1',
    });
    await expect(svc.update(n.id, '   ', 'u1')).rejects.toThrow(InvalidInputError);
  });
});

describe('NotesService.delete — удаление + удаление аудио-файла', () => {
  it('удаление audio-заметки чистит S3-объект', async () => {
    const state = mkPrisma();
    const files = mkFiles();
    const svc = new NotesService(state.prisma, mkFeed(), files);
    const n = await svc.create({
      scope: 'personal',
      kind: 'audio',
      audioKey: 'notes/audio/x.m4a',
      audioMimeType: 'audio/m4a',
      projectId: 'p1',
      authorId: 'u1',
    });
    await svc.delete(n.id, 'u1');
    expect(files.removeObject).toHaveBeenCalledWith('notes/audio/x.m4a');
  });

  it('удаление text-заметки не трогает S3', async () => {
    const state = mkPrisma();
    const files = mkFiles();
    const svc = new NotesService(state.prisma, mkFeed(), files);
    const n = await svc.create({
      scope: 'personal',
      text: 'x',
      projectId: 'p1',
      authorId: 'u1',
    });
    await svc.delete(n.id, 'u1');
    expect(files.removeObject).not.toHaveBeenCalled();
  });
});
