import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { ChatMessage, Prisma } from '@prisma/client';
import {
  Clock,
  ConflictError,
  ErrorCodes,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
  decodeCursor,
  encodeCursor,
} from '@app/common';
import { FeedService } from '../feed/feed.service';
import { ChatsService } from './chats.service';
import { SerializedMessage } from './dto';

/**
 * Окно редактирования сообщения.
 */
const EDIT_WINDOW_MS = 15 * 60 * 1000;
const DELETED_PLACEHOLDER = '(сообщение удалено)';

@Injectable()
export class MessagesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly feed: FeedService,
    private readonly events: EventEmitter2,
    private readonly chats: ChatsService,
  ) {}

  async list(
    chatId: string,
    actorUserId: string,
    opts: { cursor?: string; limit?: number } = {},
  ): Promise<{ items: SerializedMessage[]; nextCursor: string | null }> {
    // Проверяем участие: soft-left (leftAt != null) теряет доступ моментально
    // — инвариант ТЗ §10.3 «удалённый не получает новых сообщений и не
    // читает дальше». Раньше проверка была только на наличие записи →
    // пожизненный read-доступ после soft-remove. Совпадает с chats.service.get.
    const participant = await this.prisma.chatParticipant.findUnique({
      where: { chatId_userId: { chatId, userId: actorUserId } },
    });
    const isActive = participant !== null && participant.leftAt === null;
    if (!isActive) {
      // Customer может видеть если visibleToCustomer (RBAC сам разрешил)
      const chat = await this.prisma.chat.findUnique({
        where: { id: chatId },
        select: { visibleToCustomer: true, type: true },
      });
      if (!chat?.visibleToCustomer) {
        throw new ForbiddenError(ErrorCodes.CHAT_NOT_PARTICIPANT, 'not participant');
      }
    }

    const limit = Math.min(Math.max(opts.limit ?? 50, 1), 100);
    const cursor = decodeCursor<{ createdAtIso: string; id: string }>(opts.cursor);

    const where: Prisma.ChatMessageWhereInput = { chatId };
    if (cursor) {
      where.OR = [
        { createdAt: { lt: new Date(cursor.createdAtIso) } },
        {
          createdAt: new Date(cursor.createdAtIso),
          id: { lt: cursor.id },
        },
      ];
    }

    const items = await this.prisma.chatMessage.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
    });
    const hasMore = items.length > limit;
    const page = items.slice(0, limit);
    const nextCursor = hasMore
      ? encodeCursor({
          createdAtIso: page[page.length - 1].createdAt.toISOString(),
          id: page[page.length - 1].id,
        })
      : null;

    return {
      items: page.map((m) => this.serialize(m)),
      nextCursor,
    };
  }

  async create(
    chatId: string,
    actorUserId: string,
    input: { text?: string; attachmentKeys?: string[] },
  ): Promise<SerializedMessage> {
    await this.chats.assertNotArchived(chatId);
    await this.chats.assertActiveParticipant(chatId, actorUserId);

    // П1.1 — вложения в чате убраны полностью. Любая попытка прислать attachmentKeys → 400.
    if (Array.isArray(input.attachmentKeys) && input.attachmentKeys.length > 0) {
      throw new InvalidInputError(
        ErrorCodes.CHAT_MESSAGE_EMPTY,
        'attachments are disabled in chat (П1.1)',
      );
    }

    const hasText = !!input.text?.trim();
    if (!hasText) {
      throw new InvalidInputError(ErrorCodes.CHAT_MESSAGE_EMPTY, 'message requires text');
    }

    const chat = await this.prisma.chat.findUnique({
      where: { id: chatId },
      select: { projectId: true },
    });
    // Имя автора + project title для push-уведомлений. Без preview шаблон
    // chat_message_new рендерил пустое тело: `String(p.preview ?? '')` → ''.
    const author = await this.prisma.user.findUnique({
      where: { id: actorUserId },
      select: { firstName: true, lastName: true },
    });
    const project = chat?.projectId
      ? await this.prisma.project.findUnique({
          where: { id: chat.projectId },
          select: { title: true },
        })
      : null;
    const trimmedText = input.text!.trim();
    const preview = buildPreview(author, project, trimmedText);
    const authorName = formatAuthorName(author);

    const message = await this.prisma.$transaction(async (tx) => {
      const m = await tx.chatMessage.create({
        data: {
          chatId,
          authorId: actorUserId,
          text: trimmedText,
          attachmentKeys: [],
          createdAt: this.clock.now(),
        },
      });
      await this.feed.emit({
        kind: 'chat_message_sent',
        projectId: chat?.projectId ?? null,
        actorId: actorUserId,
        payload: {
          chatId,
          messageId: m.id,
          preview,
          authorName,
          projectTitle: project?.title ?? null,
        },
        tx,
      });
      return m;
    });

    const serialized = this.serialize(message);
    this.events.emit('chat.message.sent', {
      chatId,
      message: serialized,
      projectId: chat?.projectId,
    });
    return serialized;
  }

  async edit(messageId: string, actorUserId: string, newText: string): Promise<SerializedMessage> {
    const msg = await this.prisma.chatMessage.findUnique({ where: { id: messageId } });
    if (!msg) throw new NotFoundError(ErrorCodes.CHAT_MESSAGE_NOT_FOUND, 'message not found');
    if (msg.deletedAt) {
      throw new ConflictError(ErrorCodes.CHAT_MESSAGE_DELETED, 'message already deleted');
    }
    if (msg.authorId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.CHAT_MESSAGE_EDIT_AUTHOR_ONLY, 'edit only by author');
    }
    const now = this.clock.now();
    if (now.getTime() - msg.createdAt.getTime() > EDIT_WINDOW_MS) {
      throw new ConflictError(
        ErrorCodes.CHAT_MESSAGE_EDIT_WINDOW_EXPIRED,
        'edit window expired (15 min)',
      );
    }
    const updated = await this.prisma.chatMessage.update({
      where: { id: messageId },
      data: { text: newText.trim(), editedAt: now },
    });
    this.events.emit('chat.message.edited', {
      chatId: msg.chatId,
      messageId,
      text: updated.text,
    });
    return this.serialize(updated);
  }

  async softDelete(messageId: string, actorUserId: string): Promise<void> {
    const msg = await this.prisma.chatMessage.findUnique({ where: { id: messageId } });
    if (!msg) throw new NotFoundError(ErrorCodes.CHAT_MESSAGE_NOT_FOUND, 'message not found');
    if (msg.deletedAt) return; // idempotent
    // Автор или chat-creator или admin (admin проходит на уровне RBAC, сюда не доходит если не разрешено)
    const chat = await this.prisma.chat.findUnique({
      where: { id: msg.chatId },
      select: { createdById: true, projectId: true },
    });
    const isCreator = chat?.createdById === actorUserId;
    if (msg.authorId !== actorUserId && !isCreator) {
      // Owner проекта тоже разрешён (проверено гвардом). Здесь защитная проверка.
      const projectOwner = chat?.projectId
        ? await this.prisma.project.findUnique({
            where: { id: chat.projectId },
            select: { ownerId: true },
          })
        : null;
      if (projectOwner?.ownerId !== actorUserId) {
        throw new ForbiddenError(
          ErrorCodes.CHAT_MESSAGE_EDIT_AUTHOR_ONLY,
          'only author, chat-creator, or project-owner can delete',
        );
      }
    }
    await this.prisma.chatMessage.update({
      where: { id: messageId },
      data: { deletedAt: this.clock.now(), text: DELETED_PLACEHOLDER, attachmentKeys: [] },
    });
    this.events.emit('chat.message.deleted', { chatId: msg.chatId, messageId });
  }

  /**
   * П1.2 — кнопка «Переслать» убрана из UI. Endpoint оставлен для возможного возврата фичи,
   * но в admin-API/публичном клиенте маршрут не подключён. Метод по-прежнему работает,
   * чтобы существующие forward-связи (forwardedFromId) сохраняли смысл.
   */
  async forward(
    sourceMessageId: string,
    toChatId: string,
    actorUserId: string,
  ): Promise<SerializedMessage> {
    const src = await this.prisma.chatMessage.findUnique({ where: { id: sourceMessageId } });
    if (!src)
      throw new NotFoundError(ErrorCodes.CHAT_MESSAGE_NOT_FOUND, 'source message not found');
    if (src.deletedAt) {
      throw new ConflictError(ErrorCodes.CHAT_MESSAGE_DELETED, 'cannot forward deleted message');
    }
    await this.chats.assertNotArchived(toChatId);
    await this.chats.assertActiveParticipant(toChatId, actorUserId);

    const chat = await this.prisma.chat.findUnique({
      where: { id: toChatId },
      select: { projectId: true },
    });
    const author = await this.prisma.user.findUnique({
      where: { id: actorUserId },
      select: { firstName: true, lastName: true },
    });
    const project = chat?.projectId
      ? await this.prisma.project.findUnique({
          where: { id: chat.projectId },
          select: { title: true },
        })
      : null;
    const preview = buildPreview(author, project, src.text ?? '');
    const authorName = formatAuthorName(author);
    const message = await this.prisma.$transaction(async (tx) => {
      const m = await tx.chatMessage.create({
        data: {
          chatId: toChatId,
          authorId: actorUserId,
          text: src.text,
          attachmentKeys: src.attachmentKeys,
          forwardedFromId: src.id,
          createdAt: this.clock.now(),
        },
      });
      await this.feed.emit({
        kind: 'chat_message_sent',
        projectId: chat?.projectId ?? null,
        actorId: actorUserId,
        payload: {
          chatId: toChatId,
          messageId: m.id,
          forwardedFromId: src.id,
          preview,
          authorName,
          projectTitle: project?.title ?? null,
        },
        tx,
      });
      return m;
    });
    const serialized = this.serialize(message);
    this.events.emit('chat.message.sent', {
      chatId: toChatId,
      message: serialized,
      projectId: chat?.projectId,
    });
    return serialized;
  }

  private serialize(m: ChatMessage): SerializedMessage {
    return {
      id: m.id,
      chatId: m.chatId,
      authorId: m.authorId,
      text: m.text,
      attachmentKeys: m.attachmentKeys,
      forwardedFromId: m.forwardedFromId,
      editedAt: m.editedAt,
      deletedAt: m.deletedAt,
      createdAt: m.createdAt,
    };
  }
}

function formatAuthorName(
  author: { firstName: string | null; lastName: string | null } | null,
): string {
  if (!author) return 'Участник';
  const parts = [author.firstName?.trim(), author.lastName?.trim()].filter(
    (s): s is string => !!s && s.length > 0,
  );
  return parts.length > 0 ? parts.join(' ') : 'Участник';
}

function buildPreview(
  author: { firstName: string | null; lastName: string | null } | null,
  project: { title: string | null } | null,
  text: string,
): string {
  const name = formatAuthorName(author);
  const prefix = project?.title ? `${name} (${project.title})` : name;
  const oneLine = text.replace(/\s+/g, ' ').trim();
  const trimmed = oneLine.length > 120 ? `${oneLine.slice(0, 117)}...` : oneLine;
  return trimmed ? `${prefix}: ${trimmed}` : prefix;
}
