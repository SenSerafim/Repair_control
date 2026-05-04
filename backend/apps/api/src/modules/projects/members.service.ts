import { Injectable } from '@nestjs/common';
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
}

@Injectable()
export class MembersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
    private readonly chats: ChatsService,
  ) {}

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

    const exists = await this.prisma.membership.findUnique({
      where: {
        projectId_userId_role: {
          projectId: input.projectId,
          userId: input.userId,
          role: input.role,
        },
      },
    });
    if (exists) throw new ConflictError(ErrorCodes.MEMBERSHIP_EXISTS, 'membership exists');

    const permissions =
      input.role === 'representative' ? sanitizeRepresentativeRights(input.permissions as any) : {};

    const created = await this.prisma.$transaction(async (tx) => {
      const m = await tx.membership.create({
        data: {
          projectId: input.projectId,
          userId: input.userId,
          role: input.role,
          invitedById: input.actorUserId,
          permissions: permissions as Prisma.InputJsonValue,
          stageIds: input.stageIds ?? [],
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

    // П2.10 — каждый новый участник проекта автоматически попадает в общий project-чат.
    // Чат создаётся лениво при первом appearance (foreman, customer-self, etc.).
    // Вне транзакции, чтобы не блокировать на Redis/socket — но если упадёт, не ронять membership.
    try {
      await this.chats.ensureProjectChat(input.projectId, input.actorUserId);
      await this.chats.addProjectChatParticipant(input.projectId, input.userId);
    } catch (e) {
      // logger из FeedService ловит; membership уже создан — не откатываем
    }

    return created;
  }

  /**
   * П2.16 — выход участника из команды (self-removal).
   * Soft-removal: membership.removedAt = now(), доступ к проекту/чату теряется моментально (см. fillter
   * по removedAt в listForUser/AccessGuard).
   *
   * Параллельно решает судьбу инструментов (П2.15):
   *   - transfer_to_owner: ownerId всех инструментов меняется на заказчика, ToolIssuance сохраняется.
   *   - take_away: инструменты удаляются из проекта (projectId=null), активные ToolIssuance принудительно
   *     завершаются (force_returned), мастер получает уведомление.
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

      // 3. Tools (П2.15).
      const myTools = await tx.toolItem.findMany({
        where: { ownerId: userId, projectId },
      });
      if (myTools.length > 0) {
        if (action === 'transfer_to_owner') {
          await tx.toolItem.updateMany({
            where: { ownerId: userId, projectId },
            data: { ownerId: project.ownerId },
          });
        } else {
          // take_away — принудительно завершаем активные issuances + удаляем из проекта.
          for (const tool of myTools) {
            const active = await tx.toolIssuance.findMany({
              where: {
                toolItemId: tool.id,
                status: {
                  in: ['requested', 'approved', 'issued', 'confirmed', 'return_requested'],
                },
              },
            });
            for (const iss of active) {
              await tx.toolIssuance.update({
                where: { id: iss.id },
                data: { status: 'returned', returnConfirmedAt: new Date() },
              });
              await this.feed.emit({
                tx,
                kind: 'tool_force_returned',
                projectId,
                actorId: actorUserId,
                payload: { toolId: tool.id, toUserId: iss.toUserId },
              });
            }
          }
          await tx.toolItem.updateMany({
            where: { ownerId: userId, projectId },
            data: { projectId: null },
          });
        }
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
