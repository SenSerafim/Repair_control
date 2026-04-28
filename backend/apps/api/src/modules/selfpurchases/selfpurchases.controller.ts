import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { SelfPurchaseStatus } from '@prisma/client';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { PrismaService } from '@app/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { Idempotent } from '../idempotency/idempotent.decorator';
import { SelfPurchasesService, SelfPurchaseViewer } from './selfpurchases.service';
import { CreateSelfPurchaseDto, DecideSelfPurchaseDto } from './dto';

@ApiTags('selfpurchases')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller()
export class SelfPurchasesController {
  constructor(
    private readonly svc: SelfPurchasesService,
    private readonly prisma: PrismaService,
  ) {}

  private async buildViewer(userId: string, projectId: string): Promise<SelfPurchaseViewer> {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { ownerId: true },
    });
    const membership = await this.prisma.membership.findFirst({
      where: { projectId, userId },
      select: { role: true, permissions: true },
    });
    const perms = (membership?.permissions ?? {}) as { canApprove?: boolean };
    return {
      userId,
      isOwner: project?.ownerId === userId,
      membershipRole: membership?.role as SelfPurchaseViewer['membershipRole'],
      canApprove: perms.canApprove === true,
    };
  }

  @Post('projects/:projectId/selfpurchases')
  @Idempotent()
  @RequireAccess({
    action: 'selfpurchase.create',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async create(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Headers('idempotency-key') idempotencyKey: string,
    @Body() dto: CreateSelfPurchaseDto,
  ) {
    return this.svc.create({
      projectId,
      stageId: dto.stageId,
      amount: dto.amount,
      comment: dto.comment,
      photoKeys: dto.photoKeys,
      actorUserId: req.user.userId,
      idempotencyKey,
    });
  }

  @Get('projects/:projectId/selfpurchases')
  @RequireAccess({
    action: 'chat.read',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async list(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Query('status') status?: SelfPurchaseStatus,
    @Query('byUserId') byUserId?: string,
  ) {
    const viewer = await this.buildViewer(req.user.userId, projectId);
    return this.svc.listForProject(projectId, viewer, { status, byUserId });
  }

  @Get('selfpurchases/:id')
  async get(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    const sp = await this.prisma.selfPurchase.findUnique({
      where: { id },
      select: { projectId: true },
    });
    const viewer = sp
      ? await this.buildViewer(req.user.userId, sp.projectId)
      : { userId: req.user.userId };
    return this.svc.get(id, viewer);
  }

  @Post('selfpurchases/:id/approve')
  @HttpCode(200)
  @RequireAccess({
    action: 'selfpurchase.confirm',
    resource: 'selfpurchase',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  async approve(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: DecideSelfPurchaseDto,
  ) {
    return this.svc.decide(id, {
      decision: 'approved',
      comment: dto.comment,
      actorUserId: req.user.userId,
      forwardOnApprove: dto.forwardOnApprove,
    });
  }

  @Post('selfpurchases/:id/reject')
  @HttpCode(200)
  @RequireAccess({
    action: 'selfpurchase.confirm',
    resource: 'selfpurchase',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  async reject(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: DecideSelfPurchaseDto,
  ) {
    return this.svc.decide(id, {
      decision: 'rejected',
      comment: dto.comment,
      actorUserId: req.user.userId,
    });
  }
}
