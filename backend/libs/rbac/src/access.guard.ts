import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ForbiddenError, ErrorCodes, PrismaService } from '@app/common';
import { AccessRequirement, REQUIRE_ACCESS_KEY } from './access.decorator';
import { AccessContext, SystemRole } from './rbac.types';
import { canAccess } from './rbac.matrix';
import { sanitizeRepresentativeRights } from './representative-rights';

/**
 * AccessGuard — единая точка решения о доступе ко всем защищённым эндпоинтам (ТЗ §1.5).
 * Роль пользователя + участие в проекте (membership) + права представителя → решение по действию.
 *
 * Ожидает, что до guard'а выполнен JwtAuthGuard и в request.user лежит { userId, systemRole, ... }.
 */
@Injectable()
export class AccessGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const requirement = this.reflector.getAllAndOverride<AccessRequirement | undefined>(
      REQUIRE_ACCESS_KEY,
      [ctx.getHandler(), ctx.getClass()],
    );
    if (!requirement) return true;

    const req = ctx.switchToHttp().getRequest();
    const user = req.user as { userId: string; systemRole: SystemRole } | undefined;
    if (!user) throw new ForbiddenError(ErrorCodes.FORBIDDEN, 'not authenticated');

    const accessCtx: AccessContext = {
      userId: user.userId,
      systemRole: user.systemRole,
    };

    if (requirement.resource === 'project' && requirement.resourceIdFrom) {
      const projectId = this.extractId(req, requirement.resourceIdFrom);
      if (projectId) {
        await this.hydrateProjectContext(accessCtx, projectId);
      }
    } else if (requirement.resource === 'stage' && requirement.resourceIdFrom) {
      const stageId = this.extractId(req, requirement.resourceIdFrom);
      if (stageId) {
        await this.hydrateStageContext(accessCtx, stageId);
      }
    } else if (requirement.resource === 'step' && requirement.resourceIdFrom) {
      const stepId = this.extractId(req, requirement.resourceIdFrom);
      if (stepId) {
        await this.hydrateStepContext(accessCtx, stepId);
      }
    } else if (requirement.resource === 'material_request' && requirement.resourceIdFrom) {
      const materialRequestId = this.extractId(req, requirement.resourceIdFrom);
      if (materialRequestId) {
        await this.hydrateMaterialRequestContext(accessCtx, materialRequestId);
      }
    }

    if (!canAccess(requirement.action, accessCtx)) {
      throw new ForbiddenError(ErrorCodes.FORBIDDEN, `forbidden action: ${requirement.action}`);
    }
    return true;
  }

  private extractId(
    req: any,
    from: NonNullable<AccessRequirement['resourceIdFrom']>,
  ): string | undefined {
    const bag = req[from.source] ?? {};
    return bag?.[from.key];
  }

  private async hydrateProjectContext(acc: AccessContext, projectId: string): Promise<void> {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { ownerId: true, memberships: { where: { userId: acc.userId } } },
    });
    if (!project) return;
    acc.projectOwnerId = project.ownerId;
    const m = project.memberships[0];
    if (m) {
      acc.membershipRole = m.role;
      acc.representativeRights = sanitizeRepresentativeRights(m.permissions as any);
    }
  }

  private async hydrateStageContext(acc: AccessContext, stageId: string): Promise<void> {
    const stage = await this.prisma.stage.findUnique({
      where: { id: stageId },
      select: {
        foremanIds: true,
        project: {
          select: { id: true, ownerId: true, memberships: { where: { userId: acc.userId } } },
        },
      },
    });
    if (!stage) return;
    acc.projectOwnerId = stage.project.ownerId;
    acc.stageForemanIds = stage.foremanIds;
    const m = stage.project.memberships[0];
    if (m) {
      acc.membershipRole = m.role;
      acc.representativeRights = sanitizeRepresentativeRights(m.permissions as any);
    }
  }

  private async hydrateMaterialRequestContext(
    acc: AccessContext,
    materialRequestId: string,
  ): Promise<void> {
    const mr = await this.prisma.materialRequest.findUnique({
      where: { id: materialRequestId },
      select: {
        projectId: true,
        project: {
          select: { ownerId: true, memberships: { where: { userId: acc.userId } } },
        },
      },
    });
    if (!mr) return;
    acc.projectOwnerId = mr.project.ownerId;
    const m = mr.project.memberships[0];
    if (m) {
      acc.membershipRole = m.role;
      acc.representativeRights = sanitizeRepresentativeRights(m.permissions as any);
    }
  }

  private async hydrateStepContext(acc: AccessContext, stepId: string): Promise<void> {
    const step = await this.prisma.step.findUnique({
      where: { id: stepId },
      select: {
        authorId: true,
        assigneeIds: true,
        stage: {
          select: {
            foremanIds: true,
            project: {
              select: {
                id: true,
                ownerId: true,
                memberships: { where: { userId: acc.userId } },
              },
            },
          },
        },
      },
    });
    if (!step) return;
    acc.projectOwnerId = step.stage.project.ownerId;
    acc.stageForemanIds = step.stage.foremanIds;
    acc.stepAuthorId = step.authorId;
    acc.stepAssigneeIds = step.assigneeIds;
    const m = step.stage.project.memberships[0];
    if (m) {
      acc.membershipRole = m.role;
      acc.representativeRights = sanitizeRepresentativeRights(m.permissions as any);
    }
  }
}
