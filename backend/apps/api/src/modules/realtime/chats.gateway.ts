import { Logger } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { OnEvent } from '@nestjs/event-emitter';
import { Server, Socket } from 'socket.io';
import { PrismaService } from '@app/common';
import { WsAuthService, WsUser } from './ws-auth.service';

/**
 * WebSocket gateway для чатов и realtime-событий.
 * Namespace: /chats. Аутентификация — JWT в handshake.auth.token или headers.authorization.
 *
 * Комнаты:
 * - `chat:{chatId}` — участники конкретного чата (после rooms:join)
 * - `user:{userId}` — персональные уведомления (export:ready, notification:new)
 *
 * Эмит-события (server → client):
 *  - `message:new`, `message:edited`, `message:deleted`, `message:read`
 *  - `presence:typing` (broadcast)
 *  - `participant:added`, `participant:removed`
 *  - `chat:visibility_toggled`
 *  - `export:ready`, `export:failed`
 *  - `notification:new`
 */
@WebSocketGateway({ namespace: '/chats' })
export class ChatsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server!: Server;
  private readonly logger = new Logger(ChatsGateway.name);

  constructor(
    private readonly wsAuth: WsAuthService,
    private readonly prisma: PrismaService,
  ) {}

  async handleConnection(socket: Socket): Promise<void> {
    const token =
      (socket.handshake.auth?.token as string | undefined) ??
      (socket.handshake.headers.authorization as string | undefined);
    const user = await this.wsAuth.verify(token);
    if (!user) {
      // Логируем причину чтобы клиент мог понять почему его дисконнектят:
      // отсутствует токен / просрочен / пользователя нет в БД.
      const reason = !token ? 'token_missing' : 'token_invalid';
      this.logger.warn(`WS /chats auth failed (${reason}), socket=${socket.id}`);
      socket.emit('auth_error', { reason });
      socket.disconnect(true);
      return;
    }
    (socket.data as { user?: WsUser }).user = user;
    socket.join(this.userRoom(user.userId));
  }

  handleDisconnect(_socket: Socket): void {
    // socket.io сам чистит все rooms при disconnect
  }

  @SubscribeMessage('rooms:join')
  async onRoomsJoin(
    @ConnectedSocket() socket: Socket,
    @MessageBody() body: { chatIds?: string[] },
  ): Promise<{ ok: true; joined: string[] } | { ok: false; error: string }> {
    const user = (socket.data as { user?: WsUser }).user;
    if (!user) return { ok: false, error: 'unauthenticated' };
    const chatIds = Array.isArray(body?.chatIds) ? body.chatIds.filter(Boolean).slice(0, 100) : [];
    if (chatIds.length === 0) return { ok: true, joined: [] };

    const participations = await this.prisma.chatParticipant.findMany({
      where: { userId: user.userId, chatId: { in: chatIds }, leftAt: null },
      select: { chatId: true },
    });
    const joined: string[] = [];
    for (const p of participations) {
      await socket.join(this.chatRoom(p.chatId));
      joined.push(p.chatId);
    }
    return { ok: true, joined };
  }

  @SubscribeMessage('rooms:leave')
  async onRoomsLeave(
    @ConnectedSocket() socket: Socket,
    @MessageBody() body: { chatIds?: string[] },
  ): Promise<{ ok: true }> {
    const chatIds = Array.isArray(body?.chatIds) ? body.chatIds.filter(Boolean) : [];
    for (const id of chatIds) await socket.leave(this.chatRoom(id));
    return { ok: true };
  }

  @SubscribeMessage('presence:typing')
  async onTyping(
    @ConnectedSocket() socket: Socket,
    @MessageBody() body: { chatId?: string; typing?: boolean },
  ): Promise<void> {
    const user = (socket.data as { user?: WsUser }).user;
    const chatId = body?.chatId;
    if (!user || !chatId) return;
    socket
      .to(this.chatRoom(chatId))
      .emit('presence:typing', { chatId, userId: user.userId, typing: !!body.typing });
  }

  // ---------- Event-emitter subscriptions ----------

  @OnEvent('chat.message.sent')
  onMessageSent(payload: { chatId: string; message: unknown }): void {
    this.server.to(this.chatRoom(payload.chatId)).emit('message:new', payload);
  }

  @OnEvent('chat.message.edited')
  onMessageEdited(payload: { chatId: string; messageId: string; text: string | null }): void {
    this.server.to(this.chatRoom(payload.chatId)).emit('message:edited', payload);
  }

  @OnEvent('chat.message.deleted')
  onMessageDeleted(payload: { chatId: string; messageId: string }): void {
    this.server.to(this.chatRoom(payload.chatId)).emit('message:deleted', payload);
  }

  @OnEvent('chat.message.read')
  onMessageRead(payload: { chatId: string; userId: string; messageId: string }): void {
    this.server.to(this.chatRoom(payload.chatId)).emit('message:read', payload);
  }

  @OnEvent('chat.participant.added')
  onParticipantAdded(payload: { chatId: string; userId: string }): void {
    this.server.to(this.chatRoom(payload.chatId)).emit('participant:added', payload);
  }

  @OnEvent('chat.participant.removed')
  onParticipantRemoved(payload: { chatId: string; userId: string }): void {
    this.server.to(this.chatRoom(payload.chatId)).emit('participant:removed', payload);
  }

  @OnEvent('chat.visibility.toggled')
  onVisibilityToggled(payload: { chatId: string; visibleToCustomer: boolean }): void {
    this.server.to(this.chatRoom(payload.chatId)).emit('chat:visibility_toggled', payload);
  }

  @OnEvent('export.completed')
  onExportCompleted(payload: { userId: string; jobId: string; downloadUrl?: string }): void {
    this.server.to(this.userRoom(payload.userId)).emit('export:ready', payload);
  }

  @OnEvent('export.failed')
  onExportFailed(payload: { userId: string; jobId: string; error: string }): void {
    this.server.to(this.userRoom(payload.userId)).emit('export:failed', payload);
  }

  @OnEvent('notification.dispatched')
  onNotification(payload: {
    userId: string;
    kind: string;
    title: string;
    body: string;
    deepLink?: string;
  }): void {
    this.server.to(this.userRoom(payload.userId)).emit('notification:new', payload);
  }

  // ---------- helpers ----------

  private chatRoom(chatId: string): string {
    return `chat:${chatId}`;
  }

  private userRoom(userId: string): string {
    return `user:${userId}`;
  }
}
