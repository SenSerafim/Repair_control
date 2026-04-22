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
    const project = await (client as any).project.findUnique({
      where: { id: projectId },
      select: { ownerId: true, memberships: { select: { userId: true, role: true } } },
    });
    if (!project) return;
    const ids = new Set<string>();
    ids.add(project.ownerId);
    for (const m of project.memberships) {
      if (m.role === 'customer' || m.role === 'representative' || m.role === 'foreman') {
        ids.add(m.userId);
      }
    }
    for (const uid of ids) {
      await (client as any).chatParticipant.upsert({
        where: { chatId_userId: { chatId, userId: uid } },
        create: { chatId, userId: uid, joinedAt: this.clock.now() },
        update: { leftAt: null },
      });
    }
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
        participants: { some: { userId: actorUserId, leftAt: null } },
      },
      include: {
        participants: { select: { userId: true, joinedAt: true, leftAt: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return chats.map((c) => this.serialize(c));
  }

  async get(chatId: string, actorUserId: string): Promise<SerializedChat> {
    const chat = await this.prisma.chat.findUnique({
      where: { id: chatId },
      include: {
        participants: { select: { userId: true, joinedAt: true, leftAt: true } },
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
    return this.serialize(chat);
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
    chat: Chat & { participants: { userId: string; joinedAt: Date; leftAt: Date | null }[] },
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
      participants: chat.participants,
    };
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
