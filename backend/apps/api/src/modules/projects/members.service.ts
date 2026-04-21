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
    return created;
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
    await this.prisma.membership.delete({ where: { id: membershipId } });
    await this.feed.emit({
      kind: 'membership_removed',
      projectId,
      actorId: actorUserId,
      payload: { userId: membership.userId, role: membership.role },
    });
  }

  async list(projectId: string) {
    return this.prisma.membership.findMany({
      where: { projectId },
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
