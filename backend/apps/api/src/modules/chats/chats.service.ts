import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Chat, ChatType, Prisma } from '@prisma/client';
import {
  Clock,
  ConflictError,
  ErrorCodes,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { FeedService } from '../feed/feed.service';
import { SerializedChat } from './dto';

/**
 * ChatsService — CRUD чатов, автосоздание project/stage-чатов, управление участниками.
 *
 * Инварианты:
 * - По одному project-чату на проект (уникальный индекс type+projectId+stageId).
 * - По одному stage-чату на этап.
 * - Personal между user A и user B — уникальный (проверяется по паре participants).
 * - При удалении membership — soft-leave (leftAt), сообщения сохраняются (gaps §6.1).
 */
@Injectable()
export class ChatsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly feed: FeedService,
    private readonly events: EventEmitter2,
  ) {}

  // ---------- Автосоздание project/stage чатов ----------

  async ensureProjectChat(
    projectId: string,
    createdById: string,
    tx?: Prisma.TransactionClient,
  ): Promise<Chat> {
    const client = (tx ?? this.prisma) as Prisma.TransactionClient | PrismaService;
    const existing = await (client as any).chat.findFirst({
      where: { projectId, type: ChatType.project, archivedAt: null },
    });
    if (existing) return existing as Chat;
    const chat = (await (client as any).chat.create({
      data: {
        type: ChatType.project,
        projectId,
        createdById,
        title: null,
      },
    })) as Chat;
    await this.seedProjectParticipants(chat.id, projectId, client as any);
    await this.feed.emit({
      kind: 'chat_created',
      projectId,
      actorId: createdById,
      payload: { chatId: chat.id, type: 'project' },
      tx,
    });
    return chat;
  }

  async ensureStageChat(
    stageId: string,
    createdById: string,
    tx?: Prisma.TransactionClient,
  ): Promise<Chat | null> {
    const client = (tx ?? this.prisma) as Prisma.TransactionClient | PrismaService;
    const stage = await (client as any).stage.findUnique({
      where: { id: stageId },
      select: {
        id: true,
        projectId: true,
        foremanIds: true,
        project: { select: { ownerId: true, memberships: true } },
      },
    });
    if (!stage) return null;
    const existing = await (client as any).chat.findFirst({
      where: { stageId, type: ChatType.stage, archivedAt: null },
    });
    if (existing) return existing as Chat;
    const chat = (await (client as any).chat.create({
      data: {
        type: ChatType.stage,
        projectId: stage.projectId,
        stageId,
        createdById,
      },
    })) as Chat;
    const participantIds = new Set<string>();
    for (const fid of stage.foremanIds ?? []) participantIds.add(fid);
    for (const m of stage.project.memberships ?? []) {
      if (m.role === 'master' && Array.isArray(m.stageIds) && m.stageIds.includes(stageId)) {
        participantIds.add(m.userId);
      }
    }
    for (const uid of participantIds) {
      await (client as any).chatParticipant.create({
        data: { chatId: chat.id, userId: uid, joinedAt: this.clock.now() },
      });
    }
    await this.feed.emit({
      kind: 'chat_created',
      projectId: stage.projectId,
      actorId: createdById,
      payload: { chatId: chat.id, type: 'stage', stageId },
      tx,
    });
    return chat;
  }

  private async seedProjectParticipants(
    chatId: string,
    projectId: string,
    client: Prisma.TransactionClient | PrismaService,
  ): Promise<void> {
    // П2.10/П2.16 — добавляем в чат только активных (removedAt=null) участников.
    // Расширяем сидинг до всех ролей (включая master), потому что по новому решению
    // у проекта один чат на всех участников, без stage-fanout.
    const project = await (client as any).project.findUnique({
      where: { id: projectId },
      select: {
        ownerId: true,
        memberships: {
          where: { removedAt: null },
          select: { userId: true, role: true },
        },
      },
    });
    if (!project) return;
    const ids = new Set<string>();
    ids.add(project.ownerId);
    for (const m of project.memberships) {
      ids.add(m.userId);
    }
    for (const uid of ids) {
      await (client as any).chatParticipant.upsert({
        where: { chatId_userId: { chatId, userId: uid } },
        create: { chatId, userId: uid, joinedAt: this.clock.now() },
        update: { leftAt: null },
      });
    }
  }

  // ---------- Public shortcut: add/remove из project-chat ----------

  /**
   * П2.10 — каждый член проекта автоматически попадает в общий project-чат.
   * Идемпотентен: если чата ещё нет — создаст; если участник уже есть и leftAt=null — no-op.
   * Если участник был удалён (leftAt!=null) — повторно активирует (joinedAt=now, leftAt=null).
   */
  async addProjectChatParticipant(projectId: string, userId: string): Promise<void> {
    const chat = await this.ensureProjectChat(projectId, userId);
    await this.prisma.chatParticipant.upsert({
      where: { chatId_userId: { chatId: chat.id, userId } },
      create: { chatId: chat.id, userId, joinedAt: this.clock.now() },
      update: { leftAt: null, joinedAt: this.clock.now() },
    });
    this.events.emit('chat.participant.added', { chatId: chat.id, userId });
    // Личный сигнал в user:{id} комнату нового участника — `chat.participant.added`
    // бродкастится только в `chat:{chatId}` (см. ChatsGateway), а нового
    // участника там ещё нет: он не делал rooms:join. Без этого сигнала mobile
    // не узнает о чате до pull-to-refresh.
    this.events.emit('chat.user.joined', {
      userId,
      chatId: chat.id,
      projectId,
      type: chat.type,
    });
  }

  /**
   * П1.6 — удалённый из команды участник теряет доступ к чату моментально.
   * Soft-leave: leftAt=now, сообщения сохраняются.
   */
  async removeProjectChatParticipant(projectId: string, userId: string): Promise<void> {
    const chat = await this.prisma.chat.findFirst({
      where: { projectId, type: ChatType.project, archivedAt: null },
      select: { id: true },
    });
    if (!chat) return;
    const participant = await this.prisma.chatParticipant.findUnique({
      where: { chatId_userId: { chatId: chat.id, userId } },
    });
    if (!participant || participant.leftAt !== null) return;
    await this.prisma.chatParticipant.update({
      where: { id: participant.id },
      data: { leftAt: this.clock.now() },
    });
    this.events.emit('chat.participant.removed', { chatId: chat.id, userId });
  }

  // ---------- leaveAllChats (при удалении membership) ----------

  async leaveAllChats(userId: string, projectId: string): Promise<void> {
    const participations = await this.prisma.chatParticipant.findMany({
      where: {
        userId,
        leftAt: null,
        chat: { projectId },
      },
      select: { id: true, chatId: true },
    });
    const now = this.clock.now();
    for (const p of participations) {
      await this.prisma.chatParticipant.update({
        where: { id: p.id },
        data: { leftAt: now },
      });
      this.events.emit('chat.participant.removed', { chatId: p.chatId, userId });
      await this.feed.emit({
        kind: 'chat_participant_removed',
        projectId,
        actorId: userId,
        payload: { chatId: p.chatId, userId },
      });
    }
  }

  // ---------- Public: listForProject ----------

  async listForProject(projectId: string, actorUserId: string): Promise<SerializedChat[]> {
    const chats = await this.prisma.chat.findMany({
      where: {
        projectId,
        archivedAt: null,
        // По решению заказчика — один общий чат проекта на всех. Stage-чаты
        // остаются в БД для совместимости, но в inbox не показываем —
        // иначе foreman/master видит дубль project+stage по одному и тому
        // же поводу. Personal/group — оставляем.
        type: { in: [ChatType.project, ChatType.personal, ChatType.group] },
        participants: { some: { userId: actorUserId, leftAt: null } },
      },
      include: {
        participants: {
          select: { userId: true, joinedAt: true, leftAt: true, lastReadAt: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    return this.enrichManyWithLastMessageAndUnread(chats, actorUserId);
  }

  /**
   * Список всех чатов пользователя через все активные проекты.
   * Используется на mobile-табе «Чаты» (агрегированный inbox), чтобы
   * не заставлять пользователя сначала открывать конкретный проект.
   *
   * Возвращает чаты вместе с `project: { id, title }` — клиент группирует
   * их по проекту для UX «папка по проекту».
   */
  async listForUser(
    actorUserId: string,
  ): Promise<(SerializedChat & { project: { id: string; title: string } })[]> {
    const chats = await this.prisma.chat.findMany({
      where: {
        archivedAt: null,
        // только проекты, которые ещё активны (не в архиве)
        project: { archivedAt: null },
        type: { in: [ChatType.project, ChatType.personal, ChatType.group] },
        participants: { some: { userId: actorUserId, leftAt: null } },
      },
      include: {
        participants: {
          select: { userId: true, joinedAt: true, leftAt: true, lastReadAt: true },
        },
        project: { select: { id: true, title: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    const filtered = chats.filter(
      (c): c is typeof c & { project: { id: string; title: string } } => c.project !== null,
    );
    const enriched = await this.enrichManyWithLastMessageAndUnread(filtered, actorUserId);
    return enriched.map((s, i) => ({
      ...s,
      project: { id: filtered[i].project.id, title: filtered[i].project.title },
    }));
  }

  async get(chatId: string, actorUserId: string): Promise<SerializedChat> {
    const chat = await this.prisma.chat.findUnique({
      where: { id: chatId },
      include: {
        participants: {
          select: { userId: true, joinedAt: true, leftAt: true, lastReadAt: true },
        },
      },
    });
    if (!chat) throw new NotFoundError(ErrorCodes.CHAT_NOT_FOUND, 'chat not found');
    const isParticipant = chat.participants.some(
      (p) => p.userId === actorUserId && p.leftAt === null,
    );
    if (
      !isParticipant &&
      !(chat.type === 'stage' || chat.type === 'group') &&
      !chat.visibleToCustomer
    ) {
      // guard подхватит; здесь — защитный layer
      throw new ForbiddenError(ErrorCodes.CHAT_NOT_PARTICIPANT, 'not a chat participant');
    }
    const [enriched] = await this.enrichManyWithLastMessageAndUnread([chat], actorUserId);
    return enriched;
  }

  // ---------- createPersonal ----------

  async createPersonal(
    projectId: string,
    actorUserId: string,
    withUserId: string,
  ): Promise<SerializedChat> {
    if (actorUserId === withUserId) {
      throw new InvalidInputError(
        ErrorCodes.CHAT_PERSONAL_SELF_FORBIDDEN,
        'cannot open personal chat with yourself',
      );
    }
    // Проверяем, что оба — участники проекта
    const memberships = await this.prisma.membership.findMany({
      where: { projectId, userId: { in: [actorUserId, withUserId] } },
    });
    if (memberships.length < 2) {
      // owner проекта membership'а не имеет — проверяем отдельно
      const project = await this.prisma.project.findUnique({
        where: { id: projectId },
        select: { ownerId: true },
      });
      const owner = project?.ownerId;
      const hasActor = memberships.some((m) => m.userId === actorUserId) || owner === actorUserId;
      const hasTarget = memberships.some((m) => m.userId === withUserId) || owner === withUserId;
      if (!hasActor || !hasTarget) {
        throw new InvalidInputError(
          ErrorCodes.CHAT_PERSONAL_TARGET_NOT_MEMBER,
          'target user is not a project member',
        );
      }
    }
    // Ищем существующий personal-чат между двумя юзерами в рамках проекта
    const existing = await this.prisma.chat.findFirst({
      where: {
        projectId,
        type: ChatType.personal,
        archivedAt: null,
        participants: {
          every: { userId: { in: [actorUserId, withUserId] }, leftAt: null },
        },
      },
      include: {
        participants: { select: { userId: true, joinedAt: true, leftAt: true } },
      },
    });
    if (existing && existing.participants.length === 2) {
      return this.serialize(existing);
    }
    const chat = await this.prisma.$transaction(async (tx) => {
      const c = await tx.chat.create({
        data: {
          type: ChatType.personal,
          projectId,
          createdById: actorUserId,
        },
      });
      const now = this.clock.now();
      await tx.chatParticipant.createMany({
        data: [
          { chatId: c.id, userId: actorUserId, joinedAt: now },
          { chatId: c.id, userId: withUserId, joinedAt: now },
        ],
      });
      await this.feed.emit({
        kind: 'chat_created',
        projectId,
        actorId: actorUserId,
        payload: { chatId: c.id, type: 'personal', withUserId },
        tx,
      });
      return tx.chat.findUnique({
        where: { id: c.id },
        include: { participants: { select: { userId: true, joinedAt: true, leftAt: true } } },
      });
    });
    return this.serialize(chat!);
  }

  // ---------- createGroup ----------

  async createGroup(
    projectId: string,
    actorUserId: string,
    title: string,
    participantUserIds: string[],
  ): Promise<SerializedChat> {
    const uniqIds = Array.from(new Set([actorUserId, ...participantUserIds])).filter(Boolean);
    // Проверяем, что все — участники проекта (или owner)
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { ownerId: true, memberships: { select: { userId: true } } },
    });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');
    const validIds = new Set<string>([
      project.ownerId,
      ...project.memberships.map((m) => m.userId),
    ]);
    for (const id of uniqIds) {
      if (!validIds.has(id)) {
        throw new InvalidInputError(
          ErrorCodes.CHAT_PARTICIPANT_NOT_MEMBER,
          `user ${id} is not a project member`,
        );
      }
    }
    const chat = await this.prisma.$transaction(async (tx) => {
      const c = await tx.chat.create({
        data: {
          type: ChatType.group,
          projectId,
          createdById: actorUserId,
          title,
        },
      });
      const now = this.clock.now();
      await tx.chatParticipant.createMany({
        data: uniqIds.map((uid) => ({ chatId: c.id, userId: uid, joinedAt: now })),
      });
      await this.feed.emit({
        kind: 'chat_created',
        projectId,
        actorId: actorUserId,
        payload: { chatId: c.id, type: 'group', participants: uniqIds },
        tx,
      });
      return tx.chat.findUnique({
        where: { id: c.id },
        include: { participants: { select: { userId: true, joinedAt: true, leftAt: true } } },
      });
    });
    return this.serialize(chat!);
  }

  // ---------- patch (title + visibleToCustomer) ----------

  async patch(
    chatId: string,
    actorUserId: string,
    input: { title?: string; visibleToCustomer?: boolean },
  ): Promise<SerializedChat> {
    const chat = await this.prisma.chat.findUnique({ where: { id: chatId } });
    if (!chat) throw new NotFoundError(ErrorCodes.CHAT_NOT_FOUND, 'chat not found');

    const data: Prisma.ChatUpdateInput = {};
    if (input.title !== undefined) data.title = input.title;

    if (input.visibleToCustomer !== undefined) {
      if (chat.type !== 'stage' && chat.type !== 'group') {
        throw new InvalidInputError(
          ErrorCodes.CHAT_VISIBILITY_UNSUPPORTED_TYPE,
          'visibility toggle only for stage/group chats',
        );
      }
      data.visibleToCustomer = input.visibleToCustomer;
    }

    const updated = await this.prisma.chat.update({
      where: { id: chatId },
      data,
      include: { participants: { select: { userId: true, joinedAt: true, leftAt: true } } },
    });
    if (input.visibleToCustomer !== undefined) {
      this.events.emit('chat.visibility.toggled', {
        chatId,
        visibleToCustomer: input.visibleToCustomer,
      });
      await this.feed.emit({
        kind: 'chat_visibility_toggled',
        projectId: chat.projectId,
        actorId: actorUserId,
        payload: { chatId, visibleToCustomer: input.visibleToCustomer },
      });
    }
    return this.serialize(updated);
  }

  // ---------- addParticipant / removeParticipant ----------

  async addParticipant(
    chatId: string,
    actorUserId: string,
    userId: string,
  ): Promise<SerializedChat> {
    const chat = await this.prisma.chat.findUnique({
      where: { id: chatId },
      select: { id: true, projectId: true },
    });
    if (!chat) throw new NotFoundError(ErrorCodes.CHAT_NOT_FOUND, 'chat not found');
    if (chat.projectId) {
      const project = await this.prisma.project.findUnique({
        where: { id: chat.projectId },
        select: { ownerId: true, memberships: { select: { userId: true } } },
      });
      const valid =
        project &&
        (project.ownerId === userId || project.memberships.some((m) => m.userId === userId));
      if (!valid) {
        throw new InvalidInputError(
          ErrorCodes.CHAT_PARTICIPANT_NOT_MEMBER,
          'user is not a project member',
        );
      }
    }
    await this.prisma.chatParticipant.upsert({
      where: { chatId_userId: { chatId, userId } },
      create: { chatId, userId, joinedAt: this.clock.now() },
      update: { leftAt: null, joinedAt: this.clock.now() },
    });
    this.events.emit('chat.participant.added', { chatId, userId });
    const full = await this.prisma.chat.findUnique({
      where: { id: chatId },
      select: { type: true, projectId: true },
    });
    this.events.emit('chat.user.joined', {
      userId,
      chatId,
      projectId: full?.projectId ?? chat.projectId ?? null,
      type: full?.type ?? null,
    });
    await this.feed.emit({
      kind: 'chat_participant_added',
      projectId: chat.projectId,
      actorId: actorUserId,
      payload: { chatId, userId },
    });
    return this.get(chatId, actorUserId);
  }

  async removeParticipant(chatId: string, actorUserId: string, userId: string): Promise<void> {
    const participant = await this.prisma.chatParticipant.findUnique({
      where: { chatId_userId: { chatId, userId } },
    });
    if (!participant || participant.leftAt !== null) {
      throw new NotFoundError(
        ErrorCodes.CHAT_PARTICIPANT_NOT_FOUND,
        'active participant not found',
      );
    }
    const chat = await this.prisma.chat.findUnique({ where: { id: chatId } });
    if (!chat) throw new NotFoundError(ErrorCodes.CHAT_NOT_FOUND, 'chat not found');
    await this.prisma.chatParticipant.update({
      where: { id: participant.id },
      data: { leftAt: this.clock.now() },
    });
    this.events.emit('chat.participant.removed', { chatId, userId });
    await this.feed.emit({
      kind: 'chat_participant_removed',
      projectId: chat.projectId,
      actorId: actorUserId,
      payload: { chatId, userId },
    });
  }

  // ---------- helpers ----------

  private serialize(
    chat: Chat & {
      participants: {
        userId: string;
        joinedAt: Date;
        leftAt: Date | null;
        lastReadAt?: Date | null;
      }[];
    },
    extras?: {
      lastMessageAt?: Date | null;
      lastMessagePreview?: string | null;
      lastMessageAuthorId?: string | null;
      unreadCount?: number;
    },
  ): SerializedChat {
    return {
      id: chat.id,
      type: chat.type,
      projectId: chat.projectId,
      stageId: chat.stageId,
      title: chat.title,
      visibleToCustomer: chat.visibleToCustomer,
      createdById: chat.createdById,
      createdAt: chat.createdAt,
      participants: chat.participants.map(({ userId, joinedAt, leftAt }) => ({
        userId,
        joinedAt,
        leftAt,
      })),
      lastMessageAt: extras?.lastMessageAt ?? null,
      lastMessagePreview: extras?.lastMessagePreview ?? null,
      lastMessageAuthorId: extras?.lastMessageAuthorId ?? null,
      unreadCount: extras?.unreadCount ?? 0,
    };
  }

  /**
   * Один батч-запрос на все чаты: DISTINCT ON для последнего сообщения +
   * GROUP BY для unread. Cutoff = max(joinedAt, lastReadAt) — новый
   * участник видит всю историю (через messages.list), но «непрочитанным»
   * считается только то, что появилось после его вступления, чтобы не
   * получать спам «247 непрочитанных» на новом проекте.
   */
  private async enrichManyWithLastMessageAndUnread<
    T extends Chat & {
      participants: {
        userId: string;
        joinedAt: Date;
        leftAt: Date | null;
        lastReadAt?: Date | null;
      }[];
    },
  >(chats: T[], actorUserId: string): Promise<SerializedChat[]> {
    if (chats.length === 0) return [];
    const chatIds = chats.map((c) => c.id);

    type LastRow = {
      chatId: string;
      id: string;
      authorId: string;
      text: string | null;
      deletedAt: Date | null;
      createdAt: Date;
    };
    const lastRows = await this.prisma.$queryRaw<LastRow[]>`
      SELECT DISTINCT ON ("chatId") "chatId", "id", "authorId", "text", "deletedAt", "createdAt"
      FROM "ChatMessage"
      WHERE "chatId" IN (${Prisma.join(chatIds)})
      ORDER BY "chatId", "createdAt" DESC, "id" DESC
    `;
    const lastByChat = new Map<string, LastRow>();
    for (const r of lastRows) lastByChat.set(r.chatId, r);

    type UnreadRow = { chatId: string; count: bigint };
    const unreadRows = await this.prisma.$queryRaw<UnreadRow[]>`
      SELECT "chatId", COUNT(*)::bigint AS count
      FROM "ChatMessage"
      WHERE "chatId" IN (${Prisma.join(chatIds)})
        AND "authorId" <> ${actorUserId}
        AND "deletedAt" IS NULL
        AND "createdAt" > (
          SELECT GREATEST(
                   COALESCE("lastReadAt", to_timestamp(0)),
                   COALESCE("joinedAt", to_timestamp(0))
                 )
          FROM "ChatParticipant"
          WHERE "chatId" = "ChatMessage"."chatId" AND "userId" = ${actorUserId}
          LIMIT 1
        )
      GROUP BY "chatId"
    `;
    const unreadByChat = new Map<string, number>();
    for (const r of unreadRows) unreadByChat.set(r.chatId, Number(r.count));

    return chats.map((c) => {
      const last = lastByChat.get(c.id);
      const preview = last
        ? last.deletedAt
          ? '(сообщение удалено)'
          : (last.text ?? '').slice(0, 200) || null
        : null;
      return this.serialize(c, {
        lastMessageAt: last?.createdAt ?? null,
        lastMessagePreview: preview,
        lastMessageAuthorId: last?.authorId ?? null,
        unreadCount: unreadByChat.get(c.id) ?? 0,
      });
    });
  }

  // Helper: убедиться что actor — участник чата (используется в messages.service)
  async assertActiveParticipant(chatId: string, userId: string): Promise<void> {
    const p = await this.prisma.chatParticipant.findUnique({
      where: { chatId_userId: { chatId, userId } },
    });
    if (!p || p.leftAt !== null) {
      throw new ForbiddenError(ErrorCodes.CHAT_NOT_PARTICIPANT, 'not an active participant');
    }
  }

  async assertNotArchived(chatId: string): Promise<void> {
    const c = await this.prisma.chat.findUnique({
      where: { id: chatId },
      select: { archivedAt: true },
    });
    if (!c) throw new NotFoundError(ErrorCodes.CHAT_NOT_FOUND, 'chat not found');
    if (c.archivedAt) throw new ConflictError(ErrorCodes.CHAT_ARCHIVED, 'chat is archived');
  }
}
