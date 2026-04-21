import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { ApprovalScope, ApprovalStatus } from '@prisma/client';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { ApprovalsService } from './approvals.service';
import { CreateApprovalDto, DecideApprovalDto, ResubmitApprovalDto } from './dto';

@ApiTags('approvals')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller()
export class ApprovalsController {
  constructor(private readonly approvals: ApprovalsService) {}

  @Post('projects/:projectId/approvals')
  @RequireAccess({
    action: 'approval.request',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async create(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Body() dto: CreateApprovalDto,
  ) {
    return this.approvals.request({
      scope: dto.scope,
      projectId,
      stageId: dto.stageId,
      stepId: dto.stepId,
      addresseeId: dto.addresseeId,
      payload: dto.payload,
      attachmentKeys: dto.attachmentKeys,
      requestedById: req.user.userId,
    });
  }

  @Get('projects/:projectId/approvals')
  @RequireAccess({
    action: 'chat.read',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async list(
    @Param('projectId') projectId: string,
    @Query('scope') scope?: ApprovalScope,
    @Query('status') status?: ApprovalStatus,
    @Query('addresseeId') addresseeId?: string,
  ) {
    return this.approvals.listForProject(projectId, { scope, status, addresseeId });
  }

  @Get('approvals/:id')
  async get(@Param('id') id: string) {
    return this.approvals.get(id);
  }

  @Post('approvals/:id/approve')
  async approve(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: DecideApprovalDto,
  ) {
    return this.approvals.decide(id, {
      actorUserId: req.user.userId,
      actorSystemRole: req.user.systemRole,
      decision: 'approved',
      comment: dto.comment,
    });
  }

  @Post('approvals/:id/reject')
  async reject(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: DecideApprovalDto,
  ) {
    return this.approvals.decide(id, {
      actorUserId: req.user.userId,
      actorSystemRole: req.user.systemRole,
      decision: 'rejected',
      comment: dto.comment,
    });
  }

  @Post('approvals/:id/resubmit')
  async resubmit(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: ResubmitApprovalDto,
  ) {
    return this.approvals.resubmit(id, {
      payload: dto.payload,
      attachmentKeys: dto.attachmentKeys,
      actorUserId: req.user.userId,
    });
  }

  @Post('approvals/:id/cancel')
  async cancel(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    return this.approvals.cancel(id, req.user.userId);
  }
}
