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
    // Проверяем участие
    const participant = await this.prisma.chatParticipant.findUnique({
      where: { chatId_userId: { chatId, userId: actorUserId } },
    });
    if (!participant) {
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

    const hasText = !!input.text?.trim();
    const hasAttachments = Array.isArray(input.attachmentKeys) && input.attachmentKeys.length > 0;
    if (!hasText && !hasAttachments) {
      throw new InvalidInputError(
        ErrorCodes.CHAT_MESSAGE_EMPTY,
        'message requires text or attachments',
      );
    }

    const chat = await this.prisma.chat.findUnique({
      where: { id: chatId },
      select: { projectId: true },
    });

    const message = await this.prisma.$transaction(async (tx) => {
      const m = await tx.chatMessage.create({
        data: {
          chatId,
          authorId: actorUserId,
          text: input.text?.trim() || null,
          attachmentKeys: input.attachmentKeys ?? [],
          createdAt: this.clock.now(),
        },
      });
      await this.feed.emit({
        kind: 'chat_message_sent',
        projectId: chat?.projectId ?? null,
        actorId: actorUserId,
        payload: { chatId, messageId: m.id },
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
        payload: { chatId: toChatId, messageId: m.id, forwardedFromId: src.id },
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
