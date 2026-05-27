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
import { FeedEventKind } from '@prisma/client';
import { Server, Socket } from 'socket.io';
import { PrismaService } from '@app/common';
import {
  PROJECT_MEMBERSHIP_CHANGED_EVENT,
  ProjectMembershipChangedPayload,
} from '../projects/members.service';
import { WsAuthService, WsUser } from './ws-auth.service';

// Feed-события, после которых список approvals у участников проекта мог
// измениться. Источники:
// 1) ApprovalsService.request/decide/resubmit/cancel — эмитит approval_*.
// 2) Mirror-approval scopes (material_purchase / self_purchase) делегируют
//    decision в доменный сервис; тот эмитит свои kinds (selfpurchase_approved,
//    material_*) и обновляет approval.status напрямую через tx.approval.update.
// 3) extra_work_requested — legacy kind, оставлен на случай не-обновлённых
//    клиентов; новый код шлёт approval_requested.
const APPROVAL_FEED_KINDS: ReadonlySet<FeedEventKind> = new Set<FeedEventKind>([
  'approval_requested',
  'approval_approved',
  'approval_rejected',
  'approval_resubmitted',
  'approval_cancelled',
  'extra_work_requested',
  'stage_pending_approval',
  'selfpurchase_created',
  'selfpurchase_forwarded',
  'selfpurchase_approved',
  'selfpurchase_rejected',
  'material_request_created',
]);

// Доменные feed-события этапов и шагов. После них у участников проекта могла
// измениться структура (новый/удалённый шаг, новый подшаг, смена статуса этапа,
// новый/одобренный план). Транслируются ВСЕМ активным участникам проекта через
// их персональные `user:{id}` комнаты — клиент инвалидирует затронутые провайдеры
// без pull-to-refresh. Используется один общий wire-event `stage:changed` /
// `step:changed` / `substep:changed`, чтобы мобайл мог обрабатывать всё в одном
// listener'е по `kind`.
const STAGE_FEED_KINDS: ReadonlySet<FeedEventKind> = new Set<FeedEventKind>([
  'stage_created',
  'stage_started',
  'stage_paused',
  'stage_resumed',
  'stage_sent_to_review',
  'stage_accepted',
  'stage_rejected_by_customer',
  'foreman_assigned',
  'master_assigned',
  'master_unassigned',
  'foreman_replaced',
  'plan_approved',
  'stages_reordered',
  'stage_deadline_recalculated',
  'deadline_changed',
]);

const STEP_FEED_KINDS: ReadonlySet<FeedEventKind> = new Set<FeedEventKind>([
  'step_created',
  'step_updated',
  'step_deleted',
  'step_completed',
  'step_uncompleted',
  'steps_reordered',
]);

const SUBSTEP_FEED_KINDS: ReadonlySet<FeedEventKind> = new Set<FeedEventKind>([
  'substep_added',
  'substep_updated',
  'substep_completed',
  'substep_uncompleted',
  'substep_deleted',
]);

// Tool custody events — после которых у участников проекта мог измениться holder.
// Шлём `tool:changed` всем активным членам проекта (включая actor-а — клиент
// сам разрулит, нужно ли инвалидировать; это упрощает single-source-of-truth).
const TOOL_FEED_KINDS: ReadonlySet<FeedEventKind> = new Set<FeedEventKind>([
  'tool_added_to_project',
  'tool_removed_from_project',
  'tool_custody_changed',
]);

/**
 * WebSocket gateway для чатов и realtime-событий.
 * Namespace: /chats. Аутентификация — JWT в handshake.auth.token или headers.authorization.
 *
 * Комнаты:
 * - `chat:{chatId}` — участники конкретного чата (после rooms:join)
 * - `user:{userId}` — персональные уведомления (export:ready, notification:new,
 *   project:membership_changed)
 *
 * Эмит-события (server → client):
 *  - `message:new`, `message:edited`, `message:deleted`, `message:read`
 *  - `presence:typing` (broadcast)
 *  - `participant:added`, `participant:removed`
 *  - `chat:visibility_toggled`
 *  - `export:ready`, `export:failed`
 *  - `notification:new`
 *  - `project:membership_changed` — тихая UI-синхронизация (без push) о
 *    добавлении/удалении участника. Шлётся всем `recipientUserIds` из
 *    `MembersService.collectRecipientUserIds`, чтобы мобайл инвалидировал
 *    активные проекты / команду / список чатов у каждого участника.
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

  /**
   * Личное уведомление новому участнику чата: «тебя добавили — подтяни inbox».
   * `participant:added` идёт только в `chat:{id}`, но новый участник там ещё не
   * сидит (rooms:join у клиента происходит при открытии чата). Чтобы у нового
   * участника чат появился в списке без pull-to-refresh, шлём в его персональную
   * `user:{id}` комнату событие `chat:added` с минимальным payload — mobile
   * инвалидирует `myChatsProvider` / `projectChatsProvider`.
   */
  @OnEvent('chat.user.joined')
  onChatUserJoined(payload: {
    userId: string;
    chatId: string;
    projectId: string | null;
    type: string | null;
  }): void {
    this.server.to(this.userRoom(payload.userId)).emit('chat:added', {
      chatId: payload.chatId,
      projectId: payload.projectId,
      type: payload.type,
    });
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

  /**
   * Тихая UI-синхронизация состава команды проекта. Source:
   * `MembersService` (add/remove/leave) и `InvitationsService.joinByCode`.
   * Шлём в `user:{X}` комнаты всех `recipientUserIds`, чтобы у каждого
   * затронутого клиента мобайл инвалидировал список проектов / команды /
   * чатов без pull-to-refresh. Push не плодим — он идёт отдельным каналом
   * (`notification:new`) только адресату согласно ТЗ §13.2.
   */
  @OnEvent(PROJECT_MEMBERSHIP_CHANGED_EVENT)
  onProjectMembershipChanged(payload: ProjectMembershipChangedPayload): void {
    const wire = {
      projectId: payload.projectId,
      userId: payload.userId,
      role: payload.role,
      action: payload.action,
    };
    for (const uid of payload.recipientUserIds) {
      this.server.to(this.userRoom(uid)).emit('project:membership_changed', wire);
    }
  }

  /**
   * Точечный realtime-сигнал для approvals: каждый раз, когда статус или
   * существование approval-записи меняется (создание, decision, resubmit,
   * cancel, эскалация на следующего addressee), уведомляем addressee и
   * requester. Mobile использует это для немедленной инвалидации списка
   * approvals у заказчика/бригадира — без ожидания push.
   *
   * Часть feed-payload'ов не содержит addresseeId/requestedById (например,
   * approval_approved/rejected публикует только { approvalId, scope, ... }),
   * поэтому подгружаем стороны из БД по approvalId / селекторам mirror-сущностей.
   */
  @OnEvent('feed.emitted')
  async onFeedEmittedForApprovals(ev: {
    kind: FeedEventKind;
    projectId: string | null;
    actorId: string | null;
    payload: Record<string, unknown>;
  }): Promise<void> {
    if (!APPROVAL_FEED_KINDS.has(ev.kind) || !ev.projectId) return;
    try {
      const recipients = await this.collectApprovalRecipients(ev);
      if (recipients.size === 0) return;
      const wirePayload = {
        kind: ev.kind,
        projectId: ev.projectId,
        approvalId: (ev.payload as { approvalId?: unknown })?.approvalId ?? null,
        scope: (ev.payload as { scope?: unknown })?.scope ?? null,
      };
      for (const userId of recipients) {
        this.server.to(this.userRoom(userId)).emit('approval:changed', wirePayload);
      }
    } catch (e) {
      this.logger.warn(`approval:changed emit failed (${ev.kind}): ${(e as Error).message}`);
    }
  }

  /**
   * Real-time широковещание изменений этапов / шагов / подшагов всем активным
   * участникам проекта. Триггерится из StagesService / StepsService /
   * SubstepsService через `this.feed.emit` — общий механизм outbox.
   *
   * Транспорт: персональные `user:{id}` комнаты участников (нет необходимости
   * подписывать клиента на `project:{id}` rooms — мобайл уже сидит в своей
   * `user:{id}` после handleConnection). Это упрощает клиент и согласуется с
   * текущим подходом для `approval:changed` / `project:membership_changed`.
   *
   * Wire-event: `stage:changed` / `step:changed` / `substep:changed`.
   * Payload содержит `kind` (исходный FeedEventKind) + relevant IDs, чтобы
   * клиент мог точечно инвалидировать провайдеры (этап / список шагов этапа /
   * детали шага), а не дёргать весь дерево.
   */
  @OnEvent('feed.emitted')
  async onFeedEmittedForStageStepSubstep(ev: {
    kind: FeedEventKind;
    projectId: string | null;
    actorId: string | null;
    payload: Record<string, unknown>;
  }): Promise<void> {
    if (!ev.projectId) return;
    let wireEvent: 'stage:changed' | 'step:changed' | 'substep:changed' | null = null;
    if (STAGE_FEED_KINDS.has(ev.kind)) wireEvent = 'stage:changed';
    else if (STEP_FEED_KINDS.has(ev.kind)) wireEvent = 'step:changed';
    else if (SUBSTEP_FEED_KINDS.has(ev.kind)) wireEvent = 'substep:changed';
    if (!wireEvent) return;
    try {
      const recipients = await this.collectProjectMembers(ev.projectId);
      if (recipients.size === 0) return;
      const p = ev.payload as Record<string, unknown>;
      const wirePayload = {
        kind: ev.kind,
        projectId: ev.projectId,
        stageId: typeof p.stageId === 'string' ? p.stageId : null,
        stepId: typeof p.stepId === 'string' ? p.stepId : null,
        substepId: typeof p.substepId === 'string' ? p.substepId : null,
      };
      for (const userId of recipients) {
        this.server.to(this.userRoom(userId)).emit(wireEvent, wirePayload);
      }
    } catch (e) {
      this.logger.warn(`${wireEvent} emit failed (${ev.kind}): ${(e as Error).message}`);
    }
  }

  /**
   * Real-time широковещание изменений инструментов всем участникам проекта
   * (добавлен в проект / убран из проекта / сменил holder-а). Клиент использует
   * это для немедленной инвалидации `projectToolsBoardProvider` без push.
   *
   * Wire-event: `tool:changed`. Payload: { kind, projectId, toolItemId, holderId }.
   * Шлётся всем `user:{id}` комнатам активных участников, включая actor-а —
   * клиент сам решает, что инвалидировать (для actor-а часто уже видна локальная
   * оптимистичная мутация, но повторная инвалидация безопасна).
   */
  @OnEvent('feed.emitted')
  async onFeedEmittedForTools(ev: {
    kind: FeedEventKind;
    projectId: string | null;
    actorId: string | null;
    payload: Record<string, unknown>;
  }): Promise<void> {
    if (!ev.projectId || !TOOL_FEED_KINDS.has(ev.kind)) return;
    try {
      const recipients = await this.collectProjectMembers(ev.projectId);
      if (recipients.size === 0) return;
      const p = ev.payload as Record<string, unknown>;
      const wirePayload = {
        kind: ev.kind,
        projectId: ev.projectId,
        toolItemId: typeof p.toolItemId === 'string' ? p.toolItemId : null,
        holderId: typeof p.holderId === 'string' ? p.holderId : null,
      };
      for (const userId of recipients) {
        this.server.to(this.userRoom(userId)).emit('tool:changed', wirePayload);
      }
    } catch (e) {
      this.logger.warn(`tool:changed emit failed (${ev.kind}): ${(e as Error).message}`);
    }
  }

  /**
   * Список user-id'ов активных участников проекта. Кешируется на уровне
   * запроса (одна подписка = один find). Включает owner-customer'а, даже если
   * у него нет явного membership-record (защита от аномалии).
   */
  private async collectProjectMembers(projectId: string): Promise<Set<string>> {
    const out = new Set<string>();
    const memberships = await this.prisma.membership.findMany({
      where: { projectId, removedAt: null },
      select: { userId: true },
    });
    for (const m of memberships) out.add(m.userId);
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { ownerId: true },
    });
    if (project) out.add(project.ownerId);
    return out;
  }

  private async collectApprovalRecipients(ev: {
    actorId: string | null;
    payload: Record<string, unknown>;
  }): Promise<Set<string>> {
    const out = new Set<string>();
    const p = ev.payload as Record<string, unknown>;
    const addCandidate = (v: unknown): void => {
      if (typeof v === 'string' && v.length > 0) out.add(v);
    };
    addCandidate(p.addresseeId);
    addCandidate(p.requestedById);
    addCandidate(p.decidedById);
    addCandidate(p.forwardedToOwnerId);
    addCandidate(ev.actorId);

    const approvalId =
      typeof p.approvalId === 'string' ? p.approvalId : await this.resolveApprovalIdByMirrorKey(p);
    if (approvalId) {
      const a = await this.prisma.approval.findUnique({
        where: { id: approvalId },
        select: { addresseeId: true, requestedById: true, decidedById: true },
      });
      if (a) {
        addCandidate(a.addresseeId);
        addCandidate(a.requestedById);
        addCandidate(a.decidedById);
      }
    }
    return out;
  }

  private async resolveApprovalIdByMirrorKey(
    payload: Record<string, unknown>,
  ): Promise<string | null> {
    const selfPurchaseId =
      typeof payload.selfPurchaseId === 'string' ? payload.selfPurchaseId : null;
    if (selfPurchaseId) {
      const a = await this.prisma.approval.findFirst({
        where: {
          scope: 'self_purchase',
          payload: { path: ['selfPurchaseId'], equals: selfPurchaseId },
        },
        orderBy: { createdAt: 'desc' },
        select: { id: true },
      });
      if (a) return a.id;
    }
    const requestId = typeof payload.requestId === 'string' ? payload.requestId : null;
    if (requestId) {
      const a = await this.prisma.approval.findFirst({
        where: {
          scope: 'material_purchase',
          payload: { path: ['materialRequestId'], equals: requestId },
        },
        orderBy: { createdAt: 'desc' },
        select: { id: true },
      });
      if (a) return a.id;
    }
    return null;
  }

  // ---------- helpers ----------

  private chatRoom(chatId: string): string {
    return `chat:${chatId}`;
  }

  private userRoom(userId: string): string {
    return `user:${userId}`;
  }
}
