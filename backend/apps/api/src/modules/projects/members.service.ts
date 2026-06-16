import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Prisma } from '@prisma/client';
import {
  ConflictError,
  ErrorCodes,
  ForbiddenError,
  InvalidInputError,
  NotFoundError,
  PrismaService,
} from '@app/common';
import { sanitizeRepresentativeRights } from '@app/rbac';
import { FeedService } from '../feed/feed.service';
import { ChatsService } from '../chats/chats.service';

export type MembershipRole = 'customer' | 'representative' | 'foreman' | 'master';

export interface AddMembershipInput {
  projectId: string;
  actorUserId: string;
  userId: string;
  role: MembershipRole;
  permissions?: Record<string, unknown>;
  stageIds?: string[];
  /// Серафим 08.06.2026: специализация для роли master, опциональна.
  specialization?: string | null;
}

/**
 * Event-emitter событие тихой UI-синхронизации (без push). Слушает
 * `ChatsGateway` и бродкастит `project:membership_changed` в `user:{X}`
 * комнаты — это закрывает realtime-инвалидацию списков проектов/команды/
 * чатов у ВСЕХ участников, а не только у адресата push (ТЗ §13.2).
 */
export const PROJECT_MEMBERSHIP_CHANGED_EVENT = 'project.membership.changed';

export type MembershipChangeAction = 'added' | 'removed';

export interface ProjectMembershipChangedPayload {
  projectId: string;
  userId: string;
  role: string;
  action: MembershipChangeAction;
  /** userId-ы клиентов, которым нужна синхронизация UI (включая затронутого). */
  recipientUserIds: string[];
}

@Injectable()
export class MembersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
    private readonly chats: ChatsService,
    private readonly events: EventEmitter2,
  ) {}

  /**
   * Собирает userId клиентов для тихого WS-broadcast. Включает owner, всех
   * active-членов и `includeUserId` (затронутого — на случай removed/leave,
   * когда юзера уже вычеркнули, но ему всё равно нужно убрать проект из списка).
   */
  async collectRecipientUserIds(projectId: string, includeUserId?: string): Promise<string[]> {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: {
        ownerId: true,
        memberships: { where: { removedAt: null }, select: { userId: true } },
      },
    });
    if (!project) return includeUserId ? [includeUserId] : [];
    const ids = new Set<string>();
    ids.add(project.ownerId);
    for (const m of project.memberships) ids.add(m.userId);
    if (includeUserId) ids.add(includeUserId);
    return Array.from(ids);
  }

  emitMembershipChanged(payload: ProjectMembershipChangedPayload): void {
    this.events.emit(PROJECT_MEMBERSHIP_CHANGED_EVENT, payload);
  }

  async addMembership(input: AddMembershipInput) {
    const project = await this.prisma.project.findUnique({ where: { id: input.projectId } });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');

    // Запрет назначения себя бригадиром на свой же проект (ТЗ §1.5 граничный случай).
    if (input.role === 'foreman' && project.ownerId === input.userId) {
      throw new InvalidInputError(
        ErrorCodes.PROJECT_SELF_FOREMAN_FORBIDDEN,
        'owner cannot be foreman on their own project',
      );
    }
    if (input.role === 'customer' && input.userId !== project.ownerId) {
      throw new ForbiddenError(ErrorCodes.FORBIDDEN, 'only the owner can have role=customer');
    }

    // Defense-in-depth: AccessGuard уже пропустил actor'а через
    // `project.invite_member`, но матрица разрешает бригадиру эту action
    // (rbac.matrix.ts:38 «restricted to master role inside service»).
    // Здесь точечно проверяем приглашаемую роль:
    //   • бригадир приглашает только мастеров (ТЗ §1.5);
    //   • представитель приглашает любого, но добавить ещё одного представителя
    //     может только с canAddRepresentative (rbac.types.ts:105 / П7.x).
    if (input.actorUserId !== project.ownerId) {
      const actorMembership = await this.prisma.membership.findFirst({
        where: {
          projectId: input.projectId,
          userId: input.actorUserId,
          removedAt: null,
        },
        select: { role: true, permissions: true },
      });
      if (actorMembership?.role === 'foreman' && input.role !== 'master') {
        throw new ForbiddenError(ErrorCodes.FORBIDDEN, 'foreman can invite only masters');
      }
      if (actorMembership?.role === 'representative' && input.role === 'representative') {
        const actorPerms = (actorMembership.permissions ?? {}) as Record<
          string,
          boolean | undefined
        >;
        if (!actorPerms.canAddRepresentative) {
          throw new ForbiddenError(
            ErrorCodes.FORBIDDEN,
            'representative needs canAddRepresentative to invite another representative',
          );
        }
      }
    }

    // Unique-индекс (projectId, userId, role) не учитывает removedAt: после
    // leaveTeam запись остаётся в БД soft-removed. Если её игнорировать —
    // повторное добавление падает с P2002. Поэтому проверяем существование
    // и:
    //   • active (removedAt = null) → Conflict как и раньше;
    //   • soft-removed → реанимируем ту же строку (clear removedAt/removedById,
    //     перезаписываем invitedById/permissions/stageIds).
    const exists = await this.prisma.membership.findUnique({
      where: {
        projectId_userId_role: {
          projectId: input.projectId,
          userId: input.userId,
          role: input.role,
        },
      },
    });
    if (exists && !exists.removedAt) {
      throw new ConflictError(ErrorCodes.MEMBERSHIP_EXISTS, 'membership exists');
    }

    const permissions =
      input.role === 'representative' ? sanitizeRepresentativeRights(input.permissions as any) : {};

    const created = await this.prisma.$transaction(async (tx) => {
      const m = exists
        ? await tx.membership.update({
            where: { id: exists.id },
            data: {
              removedAt: null,
              removedById: null,
              hiddenForUser: false,
              invitedById: input.actorUserId,
              permissions: permissions as Prisma.InputJsonValue,
              stageIds: input.stageIds ?? [],
              specialization: input.role === 'master' ? (input.specialization ?? null) : null,
            },
          })
        : await tx.membership.create({
            data: {
              projectId: input.projectId,
              userId: input.userId,
              role: input.role,
              invitedById: input.actorUserId,
              permissions: permissions as Prisma.InputJsonValue,
              stageIds: input.stageIds ?? [],
              specialization: input.role === 'master' ? (input.specialization ?? null) : null,
            },
          });
      // Появление foreman включает требование согласования плана работ (ТЗ §4.4, gaps §3.2)
      if (input.role === 'foreman') {
        await tx.project.update({
          where: { id: input.projectId },
          data: { requiresPlanApproval: true },
        });
      }
      await this.feed.emit({
        tx,
        kind: 'membership_added',
        projectId: input.projectId,
        actorId: input.actorUserId,
        payload: { userId: input.userId, role: input.role },
      });
      return m;
    });

    // По текущему решению заказчика — у проекта один общий чат на всех
    // участников (см. chats.service.ts: seedProjectParticipants и listForProject
    // фильтр без stage). Любая роль, включая master, попадает в project-чат
    // сразу при добавлении в команду и получает доступ ко всей истории
    // сообщений (messages.list не ограничивает по joinedAt — gaps §6.1).
    try {
      await this.chats.ensureProjectChat(input.projectId, input.actorUserId);
      await this.chats.addProjectChatParticipant(input.projectId, input.userId);
    } catch (e) {
      // logger из FeedService ловит; membership уже создан — не откатываем
    }

    // Тихий WS-broadcast всем участникам — `ChatsGateway` шлёт
    // `project:membership_changed` в `user:{X}` комнаты, мобайл инвалидирует
    // список проектов / команду / чаты у всех затронутых клиентов.
    // Push при этом не плодится — он идёт отдельным каналом только адресату.
    const recipientUserIds = await this.collectRecipientUserIds(input.projectId, input.userId);
    this.emitMembershipChanged({
      projectId: input.projectId,
      userId: input.userId,
      role: input.role,
      action: 'added',
      recipientUserIds,
    });

    return created;
  }

  /**
   * П2.16 — выход участника из команды (self-removal).
   * Soft-removal: membership.removedAt = now(), доступ к проекту/чату теряется моментально (см. fillter
   * по removedAt в listForUser/AccessGuard).
   *
   * Судьба инструментов (self-custody модель, 2026-05-12):
   *   - transfer_to_owner: МОИ инструменты в проекте → ownerId меняется на заказчика;
   *     currentHolderId сбрасывается на нового owner-а.
   *   - take_away: МОИ инструменты в проекте → отвязываются (projectId=null), holder=я снова.
   *   Кроме того, инструменты ДРУГИХ owner-ов, которые сейчас у уходящего, автоматически
   *   возвращаются к их owner-у (custody event пишется).
   */
  async leaveTeam(
    projectId: string,
    userId: string,
    actorUserId: string,
    opts: { toolsAction?: 'transfer_to_owner' | 'take_away' } = {},
  ) {
    const membership = await this.prisma.membership.findFirst({
      where: { projectId, userId, removedAt: null },
    });
    if (!membership) {
      throw new NotFoundError(ErrorCodes.MEMBERSHIP_NOT_FOUND, 'membership not found');
    }
    if (membership.role === 'customer') {
      throw new InvalidInputError(
        ErrorCodes.FORBIDDEN,
        'owner cannot leave own project (use archive instead)',
      );
    }

    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { ownerId: true },
    });
    if (!project) throw new NotFoundError(ErrorCodes.PROJECT_NOT_FOUND, 'project not found');

    const action = opts.toolsAction ?? 'transfer_to_owner';

    await this.prisma.$transaction(async (tx) => {
      // 1. Soft-remove membership.
      await tx.membership.update({
        where: { id: membership.id },
        data: { removedAt: new Date(), removedById: actorUserId },
      });

      // 2. Покидаем все этапы (если был foreman/master).
      if (membership.role === 'foreman') {
        const activeStages = await tx.stage.findMany({
          where: {
            projectId,
            status: { in: ['active', 'paused', 'review', 'pending'] },
            foremanIds: { has: userId },
          },
        });
        for (const stage of activeStages) {
          await tx.stage.update({
            where: { id: stage.id },
            data: { foremanIds: stage.foremanIds.filter((id) => id !== userId) },
          });
        }
        // Висячие approvals — пометить requiresReassign.
        await tx.approval.updateMany({
          where: { projectId, addresseeId: userId, status: 'pending' },
          data: { requiresReassign: true },
        });
      }
      if (membership.role === 'master') {
        const stepsWithAssignment = await tx.step.findMany({
          where: { stage: { projectId }, assigneeIds: { has: userId } },
          select: { id: true, assigneeIds: true },
        });
        for (const s of stepsWithAssignment) {
          await tx.step.update({
            where: { id: s.id },
            data: { assigneeIds: s.assigneeIds.filter((id) => id !== userId) },
          });
        }
        await tx.stage.updateMany({
          where: { projectId, masterId: userId },
          data: { masterId: null },
        });
      }

      // 3. Tools (self-custody, 2026-05-12).
      //    a) МОИ инструменты в проекте.
      const myTools = await tx.toolItem.findMany({
        where: { ownerId: userId, projectId },
      });
      if (myTools.length > 0) {
        if (action === 'transfer_to_owner') {
          for (const tool of myTools) {
            await tx.toolItem.update({
              where: { id: tool.id },
              data: { ownerId: project.ownerId, currentHolderId: project.ownerId },
            });
            await tx.toolCustodyEvent.create({
              data: {
                toolItemId: tool.id,
                projectId,
                holderId: project.ownerId,
                previousHolderId: tool.currentHolderId,
                note: 'Передан заказчику (участник покинул проект)',
              },
            });
            await this.feed.emit({
              tx,
              kind: 'tool_custody_changed',
              projectId,
              actorId: actorUserId,
              payload: {
                toolItemId: tool.id,
                toolName: tool.name,
                holderId: project.ownerId,
                previousHolderId: tool.currentHolderId,
              },
            });
          }
        } else {
          // take_away — отвязываем от проекта, инструмент возвращается owner-у.
          for (const tool of myTools) {
            await tx.toolItem.update({
              where: { id: tool.id },
              data: { projectId: null, currentHolderId: userId },
            });
            await this.feed.emit({
              tx,
              kind: 'tool_removed_from_project',
              projectId,
              actorId: actorUserId,
              payload: { toolItemId: tool.id, toolName: tool.name },
            });
          }
        }
      }

      // b) Чужие инструменты, которые сейчас у уходящего → возвращаем владельцу.
      const heldByMe = await tx.toolItem.findMany({
        where: { projectId, currentHolderId: userId, NOT: { ownerId: userId } },
      });
      for (const tool of heldByMe) {
        await tx.toolItem.update({
          where: { id: tool.id },
          data: { currentHolderId: tool.ownerId },
        });
        await tx.toolCustodyEvent.create({
          data: {
            toolItemId: tool.id,
            projectId,
            holderId: tool.ownerId,
            previousHolderId: userId,
            note: 'Возвращён владельцу (держатель покинул проект)',
          },
        });
        await this.feed.emit({
          tx,
          kind: 'tool_custody_changed',
          projectId,
          actorId: actorUserId,
          payload: {
            toolItemId: tool.id,
            toolName: tool.name,
            holderId: tool.ownerId,
            previousHolderId: userId,
          },
        });
      }

      // 4. Чат — leftAt у участника.
      try {
        await this.chats.removeProjectChatParticipant(projectId, userId);
      } catch (e) {
        // не валим транзакцию из-за чата
      }

      // 5. Лента.
      await this.feed.emit({
        tx,
        kind: 'membership_left',
        projectId,
        actorId: actorUserId,
        payload: { userId, role: membership.role, toolsAction: action },
      });
    });

    // Тихий WS-broadcast: проект исчезает у вышедшего, состав обновляется
    // у остальных. recipientUserIds включает ушедшего, чтобы он сам убрал
    // проект из списка без pull-to-refresh.
    const recipientUserIds = await this.collectRecipientUserIds(projectId, userId);
    this.emitMembershipChanged({
      projectId,
      userId,
      role: membership.role,
      action: 'removed',
      recipientUserIds,
    });

    return { ok: true };
  }

  /**
   * П2.16 — персональный hide. Проект исчезает из списка пользователя, но он остаётся в команде.
   * Не влияет на чат/доступ (для возврата — отдельный endpoint unhide).
   */
  async hideForSelf(projectId: string, userId: string) {
    const membership = await this.prisma.membership.findFirst({
      where: { projectId, userId, removedAt: null },
    });
    if (!membership) {
      throw new NotFoundError(ErrorCodes.MEMBERSHIP_NOT_FOUND, 'membership not found');
    }
    await this.prisma.membership.update({
      where: { id: membership.id },
      data: { hiddenForUser: true },
    });
    await this.feed.emit({
      kind: 'membership_hidden',
      projectId,
      actorId: userId,
      payload: { userId },
    });
    return { ok: true };
  }

  async unhideForSelf(projectId: string, userId: string) {
    const membership = await this.prisma.membership.findFirst({
      where: { projectId, userId, removedAt: null },
    });
    if (!membership) {
      throw new NotFoundError(ErrorCodes.MEMBERSHIP_NOT_FOUND, 'membership not found');
    }
    await this.prisma.membership.update({
      where: { id: membership.id },
      data: { hiddenForUser: false },
    });
    return { ok: true };
  }

  async updateMembership(
    projectId: string,
    membershipId: string,
    actorUserId: string,
    update: { permissions?: Record<string, unknown>; stageIds?: string[] },
  ) {
    const membership = await this.prisma.membership.findUnique({ where: { id: membershipId } });
    if (!membership || membership.projectId !== projectId) {
      throw new NotFoundError(ErrorCodes.MEMBERSHIP_NOT_FOUND, 'membership not found');
    }
    const data: Prisma.MembershipUpdateInput = {};
    if (update.permissions && membership.role === 'representative') {
      data.permissions = sanitizeRepresentativeRights(
        update.permissions as any,
      ) as Prisma.InputJsonValue;
    }
    if (update.stageIds) {
      data.stageIds = update.stageIds;
    }
    const result = await this.prisma.membership.update({ where: { id: membershipId }, data });
    await this.feed.emit({
      kind: 'membership_added',
      projectId,
      actorId: actorUserId,
      payload: { updated: membershipId },
    });
    return result;
  }

  async removeMembership(projectId: string, membershipId: string, actorUserId: string) {
    const membership = await this.prisma.membership.findUnique({ where: { id: membershipId } });
    if (!membership || membership.projectId !== projectId) {
      throw new NotFoundError(ErrorCodes.MEMBERSHIP_NOT_FOUND, 'membership not found');
    }
    if (membership.role === 'customer') {
      throw new InvalidInputError(ErrorCodes.FORBIDDEN, 'owner membership cannot be removed');
    }

    // Service-уровневая проверка прав на удаление — AccessGuard пропустил
    // actor'а через `project.invite_member`, но удаление участника требует
    // более узких прав, чем приглашение (ТЗ §1.5, П2.12):
    //   • заказчик-владелец — может всё (через actorUserId === ownerId);
    //   • представитель — только с canManageTeam (без canInviteMembers);
    //   • бригадир — только своих мастеров (которых сам пригласил);
    //   • мастер — не может никого удалять.
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { ownerId: true },
    });
    const isOwner = project?.ownerId === actorUserId;
    if (!isOwner) {
      const actorMembership = await this.prisma.membership.findFirst({
        where: { projectId, userId: actorUserId, removedAt: null },
        select: { role: true, permissions: true },
      });
      if (!actorMembership) {
        throw new ForbiddenError(ErrorCodes.FORBIDDEN, 'not a project member');
      }
      if (actorMembership.role === 'representative') {
        const perms = (actorMembership.permissions ?? {}) as Record<string, boolean | undefined>;
        if (!perms.canManageTeam) {
          throw new ForbiddenError(
            ErrorCodes.FORBIDDEN,
            'representative needs canManageTeam to remove members',
          );
        }
      } else if (actorMembership.role === 'foreman') {
        if (membership.role !== 'master' || membership.invitedById !== actorUserId) {
          throw new ForbiddenError(
            ErrorCodes.FORBIDDEN,
            'foreman can remove only masters they invited',
          );
        }
      } else {
        // master — не может удалять никого.
        throw new ForbiddenError(ErrorCodes.FORBIDDEN, 'role cannot remove members');
      }
    }

    // H.2: удаление foreman — чистим его из foremanIds активных стадий,
    // помечаем его pending approvals requiresReassign, эмитим foreman_removed.
    // Удаление master — очищаем его из step.assigneeIds, чтобы не оставлять orphan ссылки.
    // Мастера, принадлежащие foreman'у, при удалении foreman'а НЕ удаляются автоматически.
    await this.prisma.$transaction(async (tx) => {
      if (membership.role === 'foreman') {
        const activeStages = await tx.stage.findMany({
          where: {
            projectId,
            status: { in: ['active', 'paused', 'review'] },
            foremanIds: { has: membership.userId },
          },
        });
        for (const stage of activeStages) {
          await tx.approval.updateMany({
            where: {
              stageId: stage.id,
              addresseeId: membership.userId,
              status: 'pending',
            },
            data: { requiresReassign: true },
          });
          await tx.stage.update({
            where: { id: stage.id },
            data: {
              foremanIds: stage.foremanIds.filter((id) => id !== membership.userId),
            },
          });
          await this.feed.emit({
            tx,
            kind: 'foreman_removed',
            projectId,
            actorId: actorUserId,
            payload: { stageId: stage.id, userId: membership.userId },
          });
        }
      } else if (membership.role === 'master') {
        // Очищаем userId удаляемого мастера из step.assigneeIds всех шагов проекта,
        // чтобы не остались orphan-ссылки. Массивы пересохраняем точечно.
        const stepsWithAssignment = await tx.step.findMany({
          where: {
            stage: { projectId },
            assigneeIds: { has: membership.userId },
          },
          select: { id: true, assigneeIds: true },
        });
        for (const s of stepsWithAssignment) {
          await tx.step.update({
            where: { id: s.id },
            data: { assigneeIds: s.assigneeIds.filter((id) => id !== membership.userId) },
          });
        }
      }

      await tx.membership.delete({ where: { id: membershipId } });
      await this.feed.emit({
        tx,
        kind: 'membership_removed',
        projectId,
        actorId: actorUserId,
        payload: { userId: membership.userId, role: membership.role },
      });
    });

    // Тихий WS-broadcast всем оставшимся + удалённому (чтобы он сам убрал
    // проект из своего списка).
    const recipientUserIds = await this.collectRecipientUserIds(projectId, membership.userId);
    this.emitMembershipChanged({
      projectId,
      userId: membership.userId,
      role: membership.role,
      action: 'removed',
      recipientUserIds,
    });
  }

  async list(projectId: string) {
    // П2.16 — отображаем только активных участников. Soft-removed (removedAt!=null)
    // в команде проекта не показываются.
    return this.prisma.membership.findMany({
      where: { projectId, removedAt: null },
      include: {
        user: {
          select: { id: true, firstName: true, lastName: true, phone: true, avatarUrl: true },
        },
      },
    });
  }

  /**
   * Видимость команды.
   *
   * 2026-05-13 раунд: заказчик подтвердил «мастер — одна сущность, видна всем
   * в команде проекта независимо от того, кто его пригласил». Это упрощает
   * прежнюю §1.4-иерархию (где invitedById/stage-intersection скрывали
   * мастеров от заказчика/представителя/чужого бригадира): теперь каждый
   * активный участник видит весь активный состав. Outsider'у возвращаем
   * пустой список (контроллер всё равно отдаст 403 раньше).
   */
  async listVisibleForViewer(projectId: string, viewerUserId: string) {
    const all = await this.list(projectId);
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { ownerId: true },
    });
    if (!project) return [];
    return this.applyVisibility(all, viewerUserId, project.ownerId, projectId);
  }

  /**
   * Чистый фильтр видимости: применяется к уже загруженному списку memberships.
   * Используется и `listVisibleForViewer` (per-project /members), и
   * `UsersService.listTeammates` (нижний таб «Команда»), чтобы правила
   * видимости не дрейфовали между двумя источниками. После раунда 2026-05-13
   * правило одно: активный участник проекта видит всех активных участников.
   */
  async applyVisibility<
    M extends {
      userId: string;
      role: string;
      invitedById: string | null;
      stageIds: string[];
      permissions: unknown;
    },
  >(memberships: M[], viewerUserId: string, ownerId: string, _projectId: string): Promise<M[]> {
    if (viewerUserId === ownerId) return memberships;
    if (memberships.some((m) => m.userId === viewerUserId)) return memberships;
    return [];
  }

  /** QA-баг #12: используется контроллером для проверки доступа к /members. */
  async findActive(projectId: string, userId: string) {
    return this.prisma.membership.findFirst({
      where: { projectId, userId, removedAt: null },
      select: { id: true, role: true },
    });
  }

  async searchUser(params: { phone?: string; email?: string }) {
    if (!params.phone && !params.email) return null;
    return this.prisma.user.findFirst({
      where: {
        OR: [
          params.phone ? { phone: params.phone } : undefined,
          params.email ? { email: params.email } : undefined,
        ].filter(Boolean) as Prisma.UserWhereInput[],
      },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        phone: true,
        email: true,
        avatarUrl: true,
      },
    });
  }
}
