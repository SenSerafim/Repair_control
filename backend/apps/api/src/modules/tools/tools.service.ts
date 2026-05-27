import { Injectable } from '@nestjs/common';
import { Prisma, ToolCustodyEvent, ToolItem } from '@prisma/client';
import {
  ConflictError,
  ErrorCodes,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { FeedService } from '../feed/feed.service';

export interface CreateMyToolInput {
  ownerId: string;
  name: string;
  photoKey?: string;
  serial?: string;
}

export interface CreateProjectToolInput {
  projectId: string;
  actorUserId: string;
  /// Владелец инструмента (любой member проекта). По умолчанию = actor.
  ownerId?: string;
  name: string;
  photoKey?: string;
  serial?: string;
}

export interface UpdateToolInput {
  name?: string;
  photoKey?: string;
  serial?: string;
}

export interface ProjectToolListItem extends ToolItem {
  /// Готовая lookup-таблица user'ов (id → {firstName, lastName, phone, avatarUrl}) —
  /// отдаётся списком вместе с инструментами на одном запросе, чтобы клиент не
  /// делал N+1. Все методы (list/get/claim/create/attach/detach) возвращают
  /// инструмент в этом обогащённом виде, чтобы UI сразу мог показать «у кого сейчас»
  /// + позвонить держателю по нажатию (tap-to-call).
  _owner?: PublicUser | null;
  _holder?: PublicUser | null;
}

/// Контакт участника проекта. `phone` отдаём всем member-ам — это согласовано
/// с экраном Команда (`MembersService.list*` тоже возвращает phone).
export interface PublicUser {
  id: string;
  firstName: string;
  lastName: string;
  phone: string;
  avatarUrl: string | null;
}

const PUBLIC_USER_SELECT = {
  id: true,
  firstName: true,
  lastName: true,
  phone: true,
  avatarUrl: true,
} as const;

@Injectable()
export class ToolsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
  ) {}

  // ---------- My Tools (в личном профиле, без projectId) ----------

  async createMyTool(input: CreateMyToolInput): Promise<ProjectToolListItem> {
    const tool = await this.prisma.toolItem.create({
      data: {
        ownerId: input.ownerId,
        currentHolderId: input.ownerId,
        name: input.name.trim(),
        photoKey: input.photoKey ?? null,
        serial: input.serial ?? null,
        projectId: null,
      },
    });
    return this.enrichTool(tool);
  }

  async listMyTools(ownerId: string): Promise<ProjectToolListItem[]> {
    const tools = await this.prisma.toolItem.findMany({
      where: { ownerId, projectId: null },
      orderBy: { createdAt: 'desc' },
    });
    return this.enrichTools(tools);
  }

  async getTool(id: string, viewerUserId: string): Promise<ProjectToolListItem> {
    const tool = await this.prisma.toolItem.findUnique({ where: { id } });
    if (!tool) throw new NotFoundError(ErrorCodes.TOOL_NOT_FOUND, 'tool not found');
    if (tool.ownerId === viewerUserId) return this.enrichTool(tool);
    if (tool.projectId) {
      const member = await this.prisma.membership.findFirst({
        where: { projectId: tool.projectId, userId: viewerUserId, removedAt: null },
        select: { id: true },
      });
      if (member) return this.enrichTool(tool);
    }
    throw new ForbiddenError(ErrorCodes.TOOL_ACCESS_DENIED, 'no access to tool');
  }

  async updateTool(
    id: string,
    input: UpdateToolInput,
    actorUserId: string,
  ): Promise<ProjectToolListItem> {
    const tool = await this.prisma.toolItem.findUnique({ where: { id } });
    if (!tool) throw new NotFoundError(ErrorCodes.TOOL_NOT_FOUND, 'tool not found');
    if (tool.ownerId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.TOOL_ACCESS_DENIED, 'only owner can update');
    }
    const data: Prisma.ToolItemUpdateInput = {
      name: input.name?.trim(),
      photoKey: input.photoKey,
      serial: input.serial,
    };
    const updated = await this.prisma.toolItem.update({ where: { id }, data });
    return this.enrichTool(updated);
  }

  async deleteTool(id: string, actorUserId: string): Promise<void> {
    const tool = await this.prisma.toolItem.findUnique({ where: { id } });
    if (!tool) throw new NotFoundError(ErrorCodes.TOOL_NOT_FOUND, 'tool not found');
    if (tool.ownerId !== actorUserId) {
      throw new ForbiddenError(ErrorCodes.TOOL_ACCESS_DENIED, 'only owner can delete');
    }
    // Если инструмент сейчас не у owner-а — запрещаем удалять (пока другой держит).
    if (tool.currentHolderId !== tool.ownerId) {
      throw new ConflictError(
        ErrorCodes.TOOL_ACCESS_DENIED,
        'tool is currently held by another user; ask them to return it first',
      );
    }
    await this.prisma.toolItem.delete({ where: { id } });
  }

  // ---------- Project Tools ----------

  /**
   * Создание нового инструмента сразу в проекте. Любой member может добавить.
   * Owner = указанный member (default = actor). Initial holder = owner.
   */
  async createInProject(input: CreateProjectToolInput): Promise<ProjectToolListItem> {
    await this.requireMember(input.projectId, input.actorUserId);
    const ownerId = input.ownerId ?? input.actorUserId;
    if (ownerId !== input.actorUserId) {
      await this.requireMember(input.projectId, ownerId, ErrorCodes.TOOL_OWNER_NOT_PROJECT_MEMBER);
    }
    const tool = await this.prisma.$transaction(async (tx) => {
      const created = await tx.toolItem.create({
        data: {
          ownerId,
          currentHolderId: ownerId,
          name: input.name.trim(),
          photoKey: input.photoKey ?? null,
          serial: input.serial ?? null,
          projectId: input.projectId,
        },
      });
      await tx.toolCustodyEvent.create({
        data: {
          toolItemId: created.id,
          projectId: input.projectId,
          holderId: ownerId,
          previousHolderId: null,
          note: null,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'tool_added_to_project',
        projectId: input.projectId,
        actorId: input.actorUserId,
        payload: { toolItemId: created.id, toolName: created.name, ownerId },
      });
      return created;
    });
    return this.enrichTool(tool);
  }

  /**
   * Bulk attach «из Моих инструментов в проект». Любой member может добавить
   * СВОИ инструменты в проект (чужие — нельзя). Создаёт initial custody event на owner-а.
   */
  async attachFromMy(
    projectId: string,
    toolItemIds: string[],
    actorUserId: string,
  ): Promise<ProjectToolListItem[]> {
    await this.requireMember(projectId, actorUserId);
    if (toolItemIds.length === 0) return [];
    const tools = await this.prisma.toolItem.findMany({
      where: { id: { in: toolItemIds } },
    });
    for (const t of tools) {
      if (t.ownerId !== actorUserId) {
        throw new ForbiddenError(
          ErrorCodes.TOOL_ACCESS_DENIED,
          `tool ${t.id} doesn't belong to you`,
        );
      }
    }
    const updated = await this.prisma.$transaction(async (tx) => {
      const out: ToolItem[] = [];
      for (const t of tools) {
        // Привязываем к проекту (если ещё не в нём). currentHolder сбрасываем на owner-а,
        // чтобы стартовое состояние было ясное.
        const u = await tx.toolItem.update({
          where: { id: t.id },
          data: {
            projectId,
            currentHolderId: t.ownerId,
          },
        });
        await tx.toolCustodyEvent.create({
          data: {
            toolItemId: t.id,
            projectId,
            holderId: t.ownerId,
            previousHolderId: null,
            note: null,
          },
        });
        await this.feed.emit({
          tx,
          kind: 'tool_added_to_project',
          projectId,
          actorId: actorUserId,
          payload: { toolItemId: t.id, toolName: t.name, ownerId: t.ownerId },
        });
        out.push(u);
      }
      return out;
    });
    return this.enrichTools(updated);
  }

  /**
   * Открепить инструмент от проекта (только owner). Сохраняем custody-history.
   * Возвращает инструмент в личное хранилище owner-а (currentHolderId = ownerId).
   */
  async detachFromProject(toolItemId: string, actorUserId: string): Promise<ProjectToolListItem> {
    const tool = await this.prisma.toolItem.findUnique({ where: { id: toolItemId } });
    if (!tool) throw new NotFoundError(ErrorCodes.TOOL_NOT_FOUND, 'tool not found');
    if (tool.ownerId !== actorUserId) {
      throw new ForbiddenError(
        ErrorCodes.TOOL_ACCESS_DENIED,
        'only owner can remove tool from project',
      );
    }
    if (!tool.projectId) {
      throw new InvalidInputError(ErrorCodes.TOOL_NOT_IN_PROJECT, 'tool not in any project');
    }
    const projectId = tool.projectId;
    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.toolItem.update({
        where: { id: toolItemId },
        data: { projectId: null, currentHolderId: tool.ownerId },
      });
      await this.feed.emit({
        tx,
        kind: 'tool_removed_from_project',
        projectId,
        actorId: actorUserId,
        payload: { toolItemId, toolName: tool.name },
      });
      return u;
    });
    return this.enrichTool(updated);
  }

  /**
   * Список инструментов проекта (виден всем member-ам). Возвращает инструменты
   * с обогащением owner/holder (PublicUser), чтобы клиент рисовал «у кого сейчас».
   */
  async listProjectTools(projectId: string, viewerUserId: string): Promise<ProjectToolListItem[]> {
    await this.requireMember(projectId, viewerUserId);
    const tools = await this.prisma.toolItem.findMany({
      where: { projectId },
      orderBy: { createdAt: 'desc' },
    });
    return this.enrichTools(tools);
  }

  /**
   * Self-claim: текущий пользователь отмечает «инструмент теперь у меня».
   * — Только сам пользователь, никто за него.
   * — Инструмент должен быть в проекте; user должен быть member.
   * — Если уже holder — 409 (no-op).
   */
  async claim(
    toolItemId: string,
    actorUserId: string,
    note?: string,
  ): Promise<ProjectToolListItem> {
    const tool = await this.prisma.toolItem.findUnique({ where: { id: toolItemId } });
    if (!tool) throw new NotFoundError(ErrorCodes.TOOL_NOT_FOUND, 'tool not found');
    if (!tool.projectId) {
      throw new InvalidInputError(
        ErrorCodes.TOOL_NOT_IN_PROJECT,
        'tool is not in any project — add it to a project first',
      );
    }
    await this.requireMember(tool.projectId, actorUserId, ErrorCodes.TOOL_NOT_PROJECT_MEMBER);
    if (tool.currentHolderId === actorUserId) {
      throw new ConflictError(ErrorCodes.TOOL_ALREADY_HELD_BY_YOU, 'tool is already held by you');
    }
    const previousHolderId = tool.currentHolderId;
    const projectId = tool.projectId;
    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.toolItem.update({
        where: { id: toolItemId },
        data: { currentHolderId: actorUserId },
      });
      await tx.toolCustodyEvent.create({
        data: {
          toolItemId,
          projectId,
          holderId: actorUserId,
          previousHolderId,
          note: note?.trim() || null,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'tool_custody_changed',
        projectId,
        actorId: actorUserId,
        payload: {
          toolItemId,
          toolName: tool.name,
          holderId: actorUserId,
          previousHolderId,
        },
      });
      return u;
    });
    return this.enrichTool(updated);
  }

  /**
   * История передач инструмента — для timeline на детальном экране.
   * Возвращает массив событий DESC по времени с обогащением holder-ов (PublicUser).
   */
  async listCustodyHistory(
    toolItemId: string,
    viewerUserId: string,
  ): Promise<
    (ToolCustodyEvent & { _holder: PublicUser | null; _previousHolder: PublicUser | null })[]
  > {
    const tool = await this.getTool(toolItemId, viewerUserId);
    const events = await this.prisma.toolCustodyEvent.findMany({
      where: { toolItemId: tool.id },
      orderBy: { createdAt: 'desc' },
    });
    const userIds = new Set<string>();
    for (const e of events) {
      userIds.add(e.holderId);
      if (e.previousHolderId) userIds.add(e.previousHolderId);
    }
    const usersById = await this.loadUsers(userIds);
    return events.map((e) => ({
      ...e,
      _holder: usersById.get(e.holderId) ?? null,
      _previousHolder: e.previousHolderId ? (usersById.get(e.previousHolderId) ?? null) : null,
    }));
  }

  // ---------- helpers ----------

  /// Подтянуть owner+holder одного инструмента и вернуть в формате
  /// `ProjectToolListItem` (тот же shape, что и для списка проектных
  /// инструментов). Используется во всех методах, которые отдают одну запись
  /// клиенту — чтобы UI сразу мог показать «Сейчас у …» + контакт.
  private async enrichTool(tool: ToolItem): Promise<ProjectToolListItem> {
    const ids = new Set<string>([tool.ownerId, tool.currentHolderId]);
    const usersById = await this.loadUsers(ids);
    return {
      ...tool,
      _owner: usersById.get(tool.ownerId) ?? null,
      _holder: usersById.get(tool.currentHolderId) ?? null,
    };
  }

  private async enrichTools(tools: ToolItem[]): Promise<ProjectToolListItem[]> {
    if (tools.length === 0) return [];
    const ids = new Set<string>();
    for (const t of tools) {
      ids.add(t.ownerId);
      ids.add(t.currentHolderId);
    }
    const usersById = await this.loadUsers(ids);
    return tools.map((t) => ({
      ...t,
      _owner: usersById.get(t.ownerId) ?? null,
      _holder: usersById.get(t.currentHolderId) ?? null,
    }));
  }

  private async loadUsers(ids: Set<string>): Promise<Map<string, PublicUser>> {
    if (ids.size === 0) return new Map();
    const users = await this.prisma.user.findMany({
      where: { id: { in: [...ids] } },
      select: PUBLIC_USER_SELECT,
    });
    return new Map(users.map((u) => [u.id, u]));
  }

  private async requireMember(
    projectId: string,
    userId: string,
    code: string = ErrorCodes.TOOL_NOT_PROJECT_MEMBER,
  ): Promise<void> {
    const member = await this.prisma.membership.findFirst({
      where: { projectId, userId, removedAt: null },
      select: { id: true },
    });
    if (!member) {
      throw new ForbiddenError(code, 'user is not a member of the project');
    }
  }
}
