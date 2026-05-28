import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import {
  ErrorCodes,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { FilesService } from '@app/files';
import { FeedService } from '../feed/feed.service';

export type NoteScopeInput = 'personal' | 'for_me' | 'stage' | 'team_broadcast';
export type NoteKindInput = 'text' | 'audio';
export type NoteListFilter = 'all' | 'mine' | 'team';

export interface CreateNoteInput {
  scope: NoteScopeInput;
  kind?: NoteKindInput;
  text?: string;
  audioKey?: string;
  audioMimeType?: string;
  audioDurationMs?: number;
  addresseeId?: string;
  stageId?: string;
  projectId: string;
  authorId: string;
}

export interface ListNotesParams {
  userId: string;
  projectId: string;
  scope?: NoteScopeInput;
  filter?: NoteListFilter;
  stageId?: string;
  search?: string;
}

export interface NoteWithMedia {
  id: string;
  scope: NoteScopeInput;
  kind: NoteKindInput;
  authorId: string;
  addresseeId: string | null;
  projectId: string | null;
  stageId: string | null;
  text: string | null;
  audioKey: string | null;
  audioMimeType: string | null;
  audioDurationMs: number | null;
  audioUrl: string | null;
  transcript: string | null;
  transcriptStatus: 'pending' | 'done' | 'failed' | null;
  transcriptProvider: string | null;
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class NotesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
    private readonly files: FilesService,
  ) {}

  async create(input: CreateNoteInput) {
    this.validate(input);

    const kind: NoteKindInput = input.kind ?? 'text';
    const text = input.text?.trim() || null;

    const note = await this.prisma.$transaction(async (tx) => {
      const created = await tx.note.create({
        data: {
          scope: input.scope,
          kind,
          text,
          authorId: input.authorId,
          addresseeId: input.scope === 'for_me' ? input.addresseeId : null,
          stageId: input.scope === 'stage' ? input.stageId : null,
          projectId: input.projectId,
          audioKey: kind === 'audio' ? input.audioKey : null,
          audioMimeType: kind === 'audio' ? input.audioMimeType : null,
          audioDurationMs: kind === 'audio' ? (input.audioDurationMs ?? null) : null,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'note_created',
        projectId: input.projectId,
        actorId: input.authorId,
        payload: {
          noteId: created.id,
          scope: input.scope,
          noteKind: kind,
          ...(created.addresseeId ? { addresseeId: created.addresseeId } : {}),
          ...(created.stageId ? { stageId: created.stageId } : {}),
        },
      });
      return created;
    });
    return this.enrich(note);
  }

  /**
   * П1.10 — заметка для всей команды («впрок»). Не требует получателей; разрешено создать
   * на проекте без team — станет видна всем по мере появления участников.
   */
  async createTeamBroadcast(input: { projectId: string; authorId: string; text: string }) {
    return this.create({
      scope: 'team_broadcast',
      kind: 'text',
      text: input.text,
      projectId: input.projectId,
      authorId: input.authorId,
    });
  }

  async list(params: ListNotesParams): Promise<NoteWithMedia[]> {
    // scope-правила видимости:
    // - personal → только автор
    // - for_me → addressee или автор
    // - stage → участники проекта (ниже проверка через projectId)
    // - team_broadcast → все участники проекта
    //
    // filter (NEWFIX-2 §11.5) накладывается поверх:
    // - mine → authorId=me
    // - team → scope=team_broadcast
    // - all → как раньше
    const where: Prisma.NoteWhereInput = {
      projectId: params.projectId,
    };
    if (params.stageId) where.stageId = params.stageId;
    if (params.search) where.text = { contains: params.search, mode: 'insensitive' };

    const scopes: NoteScopeInput[] = params.scope
      ? [params.scope]
      : params.filter === 'team'
        ? ['team_broadcast']
        : ['personal', 'for_me', 'stage', 'team_broadcast'];

    const or: Prisma.NoteWhereInput[] = [];
    for (const sc of scopes) {
      if (sc === 'personal') or.push({ scope: 'personal', authorId: params.userId });
      if (sc === 'for_me') {
        or.push({
          scope: 'for_me',
          OR: [{ authorId: params.userId }, { addresseeId: params.userId }],
        });
      }
      if (sc === 'stage') or.push({ scope: 'stage' });
      if (sc === 'team_broadcast') or.push({ scope: 'team_broadcast' });
    }
    where.OR = or;
    if (params.filter === 'mine') where.authorId = params.userId;

    const rows = await this.prisma.note.findMany({ where, orderBy: { createdAt: 'desc' } });
    return Promise.all(rows.map((r) => this.enrich(r)));
  }

  async get(id: string, actorUserId: string): Promise<NoteWithMedia> {
    const note = await this.prisma.note.findUnique({ where: { id } });
    if (!note) throw new NotFoundError(ErrorCodes.NOTE_NOT_FOUND, 'note not found');
    if (note.scope === 'personal' && note.authorId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.NOTE_NOT_FOUND, 'personal note access denied');
    }
    if (
      note.scope === 'for_me' &&
      note.authorId !== actorUserId &&
      note.addresseeId !== actorUserId
    ) {
      throw new ForbiddenError(ErrorCodes.NOTE_NOT_FOUND, 'for_me note access denied');
    }
    return this.enrich(note);
  }

  async update(id: string, text: string, actorUserId: string) {
    const note = await this.prisma.note.findUnique({ where: { id } });
    if (!note) throw new NotFoundError(ErrorCodes.NOTE_NOT_FOUND, 'note not found');
    if (note.authorId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.NOTE_AUTHOR_ONLY, 'only author can edit');
    }
    if (note.kind === 'text' && !text.trim()) {
      throw new InvalidInputError(ErrorCodes.NOTE_INVALID_SCOPE, 'text is required for text-note');
    }
    const trimmed = text.trim();
    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.note.update({
        where: { id },
        data: { text: trimmed.length ? trimmed : null },
      });
      await this.feed.emit({
        tx,
        kind: 'note_updated',
        projectId: note.projectId,
        actorId: actorUserId,
        payload: { noteId: id },
      });
      return u;
    });
    return this.enrich(updated);
  }

  async delete(id: string, actorUserId: string) {
    const note = await this.prisma.note.findUnique({ where: { id } });
    if (!note) throw new NotFoundError(ErrorCodes.NOTE_NOT_FOUND, 'note not found');
    if (note.authorId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.NOTE_AUTHOR_ONLY, 'only author can delete');
    }
    await this.prisma.$transaction(async (tx) => {
      await tx.note.delete({ where: { id } });
      await this.feed.emit({
        tx,
        kind: 'note_deleted',
        projectId: note.projectId,
        actorId: actorUserId,
        payload: { noteId: id },
      });
    });
    if (note.audioKey) {
      await this.files.removeObject(note.audioKey);
    }
  }

  private async enrich(row: {
    id: string;
    scope: NoteScopeInput;
    kind: NoteKindInput;
    authorId: string;
    addresseeId: string | null;
    projectId: string | null;
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
  }): Promise<NoteWithMedia> {
    let audioUrl: string | null = null;
    if (row.kind === 'audio' && row.audioKey) {
      try {
        audioUrl = (await this.files.createPresignedDownload(row.audioKey)).url;
      } catch {
        audioUrl = null;
      }
    }
    return { ...row, audioUrl };
  }

  private validate(input: CreateNoteInput) {
    if (input.scope === 'for_me' && !input.addresseeId) {
      throw new InvalidInputError(
        ErrorCodes.NOTE_ADDRESSEE_REQUIRED,
        'addresseeId required for scope=for_me',
      );
    }
    if (input.scope === 'stage' && !input.stageId) {
      throw new InvalidInputError(
        ErrorCodes.NOTE_STAGE_REQUIRED,
        'stageId required for scope=stage',
      );
    }
    const kind: NoteKindInput = input.kind ?? 'text';
    if (kind === 'text') {
      if (!input.text || !input.text.trim()) {
        throw new InvalidInputError(ErrorCodes.NOTE_INVALID_SCOPE, 'text is required');
      }
    } else {
      if (!input.audioKey || !input.audioMimeType) {
        throw new InvalidInputError(
          ErrorCodes.NOTE_INVALID_SCOPE,
          'audioKey and audioMimeType are required for kind=audio',
        );
      }
    }
  }
}
