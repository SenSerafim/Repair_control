import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Clock, ErrorCodes, ForbiddenError, NotFoundError, PrismaService } from '@app/common';

@Injectable()
export class ReadReceiptsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly events: EventEmitter2,
  ) {}

  async markRead(chatId: string, userId: string, messageId: string): Promise<void> {
    const msg = await this.prisma.chatMessage.findUnique({
      where: { id: messageId },
      select: { chatId: true, createdAt: true },
    });
    if (!msg) throw new NotFoundError(ErrorCodes.CHAT_MESSAGE_NOT_FOUND, 'message not found');
    if (msg.chatId !== chatId) {
      throw new NotFoundError(ErrorCodes.CHAT_MESSAGE_NOT_FOUND, 'message not in this chat');
    }
    const participant = await this.prisma.chatParticipant.findUnique({
      where: { chatId_userId: { chatId, userId } },
    });
    if (!participant) {
      throw new ForbiddenError(ErrorCodes.CHAT_NOT_PARTICIPANT, 'not a participant');
    }
    // lastReadAt только вперёд — не даём "откатывать назад"
    if (participant.lastReadAt && participant.lastReadAt >= msg.createdAt) {
      return;
    }
    await this.prisma.chatParticipant.update({
      where: { id: participant.id },
      data: {
        lastReadMessageId: messageId,
        lastReadAt: msg.createdAt,
      },
    });
    this.events.emit('chat.message.read', { chatId, userId, messageId });
  }

  async unreadCount(chatId: string, userId: string): Promise<number> {
    const p = await this.prisma.chatParticipant.findUnique({
      where: { chatId_userId: { chatId, userId } },
      select: { lastReadAt: true },
    });
    const cutoff = p?.lastReadAt ?? new Date(0);
    return this.prisma.chatMessage.count({
      where: {
        chatId,
        createdAt: { gt: cutoff },
        authorId: { not: userId },
        deletedAt: null,
      },
    });
  }
}
