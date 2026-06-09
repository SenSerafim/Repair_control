import { Injectable } from '@nestjs/common';
import { Prisma, ToolCondition, ToolCustodyEvent, ToolItem, ToolStatus } from '@prisma/client';
import {
  ConflictError,
  ErrorCodes,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { FeedService } from '../feed/feed.service';

export type ToolStatusInput = 'in_storage' | 'on_project' | 'with_employee';

export type ToolConditionInput = 'new_tool' | 'good' | 'worn' | 'broken';

export interface CreateMyToolInput {
  ownerId: string;
  name: string;
  article?: string;
  photoKey?: string;
  serial?: string;
  status?: ToolStatusInput;
  storageLocation?: string;
  assignedEmployeeId?: string;
  purchaseDate?: Date;
  condition?: ToolConditionInput;
}

export interface CreateProjectToolInput {
  projectId: string;
  actorUserId: string;
  /// Владелец инструмента (любой member проекта). По умолчанию = actor.
  ownerId?: string;
  name: string;
  article?: string;
  photoKey?: string;
  serial?: string;
  purchaseDate?: Date;
  condition?: ToolConditionInput;
}

export interface UpdateToolInput {
  name?: string;
  article?: string;
  photoKey?: string;
  serial?: string;
  status?: ToolStatusInput;
  storageLocation?: string;
  assignedEmployeeId?: string;
  purchaseDate?: Date | null;
  condition?: ToolConditionInput | null;
}

export interface ListMyToolsParams {
  ownerId: string;
  /// NEWFIX-2 §7.2 — поиск по подстроке `name` (case-insensitive).
  search?: string;
  /// Фильтр по статусу. Если не задан — все.
  status?: ToolStatusInput;
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
    const status: ToolStatus = (input.status as ToolStatus | undefined) ?? 'in_storage';
    this.validateStatusFields(status, {
      storageLocation: input.storageLocation,
      assignedEmployeeId: input.assignedEmployeeId,
    });
    const tool = await this.prisma.toolItem.create({
      data: {
        ownerId: input.ownerId,
        currentHolderId: input.ownerId,
        name: input.name.trim(),
        article: input.article?.trim() || null,
        photoKey: input.photoKey ?? null,
        serial: input.serial ?? null,
        purchaseDate: input.purchaseDate ?? null,
        condition: (input.condition as ToolCondition | undefined) ?? null,
        status,
        storageLocation: status === 'in_storage' ? input.storageLocation?.trim() || null : null,
        assignedEmployeeId: status === 'with_employee' ? input.assignedEmployeeId! : null,
        projectId: null,
      },
    });
    return this.enrichTool(tool);
  }

  /// NEWFIX-2 §7.2 — список «Мои инструменты» с поиском и фильтром.
  /// При status=on_project мы по-прежнему возвращаем инструмент в личной
  /// сводке владельца — даже если он сейчас находится на проекте, владельцу
  /// его видно, чтобы он мог им управлять.
  async listMyTools(params: ListMyToolsParams): Promise<ProjectToolListItem[]> {
    const where: Prisma.ToolItemWhereInput = { ownerId: params.ownerId };
    if (params.status) where.status = params.status as ToolStatus;
    if (params.search) where.name = { contains: params.search, mode: 'insensitive' };
    const tools = await this.prisma.toolItem.findMany({
      where,
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

    // Если меняется статус — валидируем согласованность связанных полей.
    const newStatus = (input.status as ToolStatus | undefined) ?? tool.status;
    if (input.status !== undefined) {
      this.validateStatusFields(newStatus, {
        storageLocation: input.storageLocation ?? tool.storageLocation ?? undefined,
        assignedEmployeeId: input.assignedEmployeeId ?? tool.assignedEmployeeId ?? undefined,
      });
    }

    const data: Prisma.ToolItemUpdateInput = {
      name: input.name?.trim(),
      article: input.article === undefined ? undefined : input.article.trim() || null,
      photoKey: input.photoKey,
      serial: input.serial,
      purchaseDate: input.purchaseDate,
      condition:
        input.condition === undefined ? undefined : (input.condition as ToolCondition | null),
    };
    if (input.status !== undefined) {
      data.status = newStatus;
      // При смене статуса очищаем нерелевантные поля; релевантные — обновляем.
      if (newStatus === 'in_storage') {
        data.storageLocation =
          input.storageLocation !== undefined
            ? input.storageLocation.trim() || null
            : tool.storageLocation;
        data.assignedEmployee = { disconnect: true };
      } else if (newStatus === 'with_employee') {
        data.storageLocation = null;
        data.assignedEmployee = { connect: { id: input.assignedEmployeeId! } };
      } else {
        // on_project — projectId меняется не здесь (через attachFromMy/createInProject).
        data.storageLocation = null;
        data.assignedEmployee = { disconnect: true };
      }
    } else {
      // Статус не меняется — обновляем только конкретные поля если пришли.
      if (input.storageLocation !== undefined) {
        data.storageLocation = input.storageLocation.trim() || null;
      }
      if (input.assignedEmployeeId !== undefined) {
        data.assignedEmployee = { connect: { id: input.assignedEmployeeId } };
      }
    }

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
          article: input.article?.trim() || null,
          photoKey: input.photoKey ?? null,
          serial: input.serial ?? null,
          purchaseDate: input.purchaseDate ?? null,
          condition: (input.condition as ToolCondition | undefined) ?? null,
          status: 'on_project',
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
   * СВОИ инструменты в проект (чужие — нельзя). Создаёт initial custody event
   * на ответственного.
   *
   * NEWFIX-2 §8.3 — ответственный по умолчанию = бригадир проекта (если есть),
   * иначе actor. Параметр `responsibleUserId` позволяет принудительно указать.
   * §8.4 — если инструмент уже на ДРУГОМ проекте — 409 Conflict (статус
   * on_project блокирует двойное назначение). Инструменты со статусом
   * with_employee «ездят» с сотрудником и тоже не привязываются дважды
   * к проектам — для них берём текущего assignedEmployee как holder.
   */
  async attachFromMy(
    projectId: string,
    toolItemIds: string[],
    actorUserId: string,
    responsibleUserId?: string,
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
      // §8.4 — блокировка дублей. Инструмент уже на другом проекте.
      if (t.projectId && t.projectId !== projectId) {
        throw new ConflictError(
          ErrorCodes.TOOL_ALREADY_ON_OTHER_PROJECT,
          `tool ${t.id} is currently on another project`,
        );
      }
    }
    // §8.3 — ответственный по умолчанию = бригадир проекта. Бригадир — это
    // первый Membership проекта с системной ролью `contractor` (исторически
    // в проекте слово «бригадир» mapped на SystemRole.contractor).
    let defaultHolderId = actorUserId;
    if (!responsibleUserId) {
      const foreman = await this.prisma.membership.findFirst({
        where: {
          projectId,
          removedAt: null,
          user: { activeRole: 'contractor' },
        },
        select: { userId: true },
      });
      if (foreman) defaultHolderId = foreman.userId;
    }
    const holderId = responsibleUserId ?? defaultHolderId;
    // Если responsibleUserId передан — проверяем что это member.
    if (responsibleUserId) {
      await this.requireMember(projectId, responsibleUserId, ErrorCodes.TOOL_NOT_PROJECT_MEMBER);
    }
    const updated = await this.prisma.$transaction(async (tx) => {
      const out: ToolItem[] = [];
      for (const t of tools) {
        const u = await tx.toolItem.update({
          where: { id: t.id },
          data: {
            projectId,
            status: 'on_project',
            storageLocation: null,
            currentHolderId: holderId,
          },
        });
        await tx.toolCustodyEvent.create({
          data: {
            toolItemId: t.id,
            projectId,
            holderId,
            previousHolderId: null,
            note: null,
          },
        });
        await this.feed.emit({
          tx,
          kind: 'tool_added_to_project',
          projectId,
          actorId: actorUserId,
          payload: {
            toolItemId: t.id,
            toolName: t.name,
            ownerId: t.ownerId,
            holderId,
          },
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
        data: {
          projectId: null,
          status: 'in_storage',
          currentHolderId: tool.ownerId,
        },
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
   * NEWFIX-2 §9 — выдать инструмент конкретному сотруднику. Точка входа из
   * профиля сотрудника (E4, экран `user_profile`). Только владелец может
   * выдать; сотрудник должен существовать.
   *
   * Инструмент переходит в статус 'with_employee', projectId сбрасывается
   * (он «ездит» с сотрудником и не привязан к одному объекту).
   * currentHolderId = сотрудник.
   */
  async assignToEmployee(
    toolItemId: string,
    employeeUserId: string,
    actorUserId: string,
  ): Promise<ProjectToolListItem> {
    const tool = await this.prisma.toolItem.findUnique({ where: { id: toolItemId } });
    if (!tool) throw new NotFoundError(ErrorCodes.TOOL_NOT_FOUND, 'tool not found');
    if (tool.ownerId !== actorUserId) {
      throw new ForbiddenError(
        ErrorCodes.TOOL_ACCESS_DENIED,
        'only owner can assign tool to employee',
      );
    }
    const employee = await this.prisma.user.findUnique({ where: { id: employeeUserId } });
    if (!employee) {
      throw new NotFoundError(ErrorCodes.TOOL_NOT_FOUND, 'employee not found');
    }
    const prevProjectId = tool.projectId;
    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.toolItem.update({
        where: { id: toolItemId },
        data: {
          status: 'with_employee',
          assignedEmployeeId: employeeUserId,
          currentHolderId: employeeUserId,
          projectId: null,
          storageLocation: null,
        },
      });
      if (prevProjectId) {
        await tx.toolCustodyEvent.create({
          data: {
            toolItemId,
            projectId: prevProjectId,
            holderId: employeeUserId,
            previousHolderId: tool.currentHolderId,
            note: 'выдан сотруднику',
          },
        });
        await this.feed.emit({
          tx,
          kind: 'tool_custody_changed',
          projectId: prevProjectId,
          actorId: actorUserId,
          payload: {
            toolItemId,
            toolName: tool.name,
            holderId: employeeUserId,
            previousHolderId: tool.currentHolderId,
          },
        });
      }
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

  /// Согласованность полей статуса (NEWFIX-2 §7.1):
  /// - in_storage: storageLocation опционален; assignedEmployeeId должен быть null
  /// - on_project: устанавливается только attach/createInProject; здесь не валидируем напрямую
  /// - with_employee: assignedEmployeeId обязателен
  private validateStatusFields(
    status: ToolStatus,
    fields: { storageLocation?: string; assignedEmployeeId?: string },
  ): void {
    if (status === 'with_employee' && !fields.assignedEmployeeId) {
      throw new InvalidInputError(
        ErrorCodes.TOOL_NOT_FOUND,
        'assignedEmployeeId required for status=with_employee',
      );
    }
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
