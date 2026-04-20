import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import {
  ErrorCodes,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { FeedService } from '../feed/feed.service';

export interface CreateNoteInput {
  scope: 'personal' | 'for_me' | 'stage';
  text: string;
  addresseeId?: string;
  stageId?: string;
  projectId: string;
  authorId: string;
}

export interface ListNotesParams {
  userId: string;
  projectId: string;
  scope?: 'personal' | 'for_me' | 'stage';
  stageId?: string;
  search?: string;
}

@Injectable()
export class NotesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
  ) {}

  async create(input: CreateNoteInput) {
    this.validate(input);

    const note = await this.prisma.$transaction(async (tx) => {
      const created = await tx.note.create({
        data: {
          scope: input.scope,
          text: input.text.trim(),
          authorId: input.authorId,
          addresseeId: input.scope === 'for_me' ? input.addresseeId : null,
          stageId: input.scope === 'stage' ? input.stageId : null,
          projectId: input.projectId,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'note_created',
        projectId: input.projectId,
        actorId: input.authorId,
        payload: { noteId: created.id, scope: input.scope },
      });
      return created;
    });
    return note;
  }

  async list(params: ListNotesParams) {
    // scope-правила видимости:
    // - personal → только автор
    // - for_me → addressee или автор
    // - stage → участники проекта (ниже проверка через projectId)
    const where: Prisma.NoteWhereInput = {
      projectId: params.projectId,
    };
    if (params.stageId) where.stageId = params.stageId;
    if (params.search) where.text = { contains: params.search, mode: 'insensitive' };

    const scopes: Array<'personal' | 'for_me' | 'stage'> = params.scope
      ? [params.scope]
      : ['personal', 'for_me', 'stage'];

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
    }
    where.OR = or;

    return this.prisma.note.findMany({ where, orderBy: { createdAt: 'desc' } });
  }

  async get(id: string, actorUserId: string) {
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
    return note;
  }

  async update(id: string, text: string, actorUserId: string) {
    const note = await this.prisma.note.findUnique({ where: { id } });
    if (!note) throw new NotFoundError(ErrorCodes.NOTE_NOT_FOUND, 'note not found');
    if (note.authorId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.NOTE_AUTHOR_ONLY, 'only author can edit');
    }
    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.note.update({ where: { id }, data: { text: text.trim() } });
      await this.feed.emit({
        tx,
        kind: 'note_updated',
        projectId: note.projectId,
        actorId: actorUserId,
        payload: { noteId: id },
      });
      return u;
    });
    return updated;
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
    if (!input.text || !input.text.trim()) {
      throw new InvalidInputError(ErrorCodes.NOTE_INVALID_SCOPE, 'text is required');
    }
  }
}
