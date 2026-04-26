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
import { PaymentKind, PaymentStatus } from '@prisma/client';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { Idempotent } from '../idempotency/idempotent.decorator';
import { PaymentsService } from './payments.service';
import { BudgetCalculator } from './budget-calculator';
import { CreateAdvanceDto, DisputePaymentDto, DistributeDto, ResolvePaymentDto } from './dto';
import { PrismaService } from '@app/common';

@ApiTags('payments')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller()
export class PaymentsController {
  constructor(
    private readonly payments: PaymentsService,
    private readonly budget: BudgetCalculator,
    private readonly prisma: PrismaService,
  ) {}

  @Post('projects/:projectId/payments')
  @Idempotent()
  @RequireAccess({
    action: 'finance.payment.create',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async createAdvance(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Headers('idempotency-key') idempotencyKey: string,
    @Body() dto: CreateAdvanceDto,
  ) {
    return this.payments.createAdvance({
      projectId,
      toUserId: dto.toUserId,
      amount: dto.amount,
      stageId: dto.stageId,
      comment: dto.comment,
      photoKey: dto.photoKey,
      actorUserId: req.user.userId,
      idempotencyKey,
    });
  }

  @Post('payments/:id/distribute')
  @Idempotent()
  async distribute(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') parentId: string,
    @Headers('idempotency-key') idempotencyKey: string,
    @Body() dto: DistributeDto,
  ) {
    return this.payments.createDistribution({
      parentPaymentId: parentId,
      toUserId: dto.toUserId,
      amount: dto.amount,
      stageId: dto.stageId,
      comment: dto.comment,
      photoKey: dto.photoKey,
      actorUserId: req.user.userId,
      idempotencyKey,
    });
  }

  @Post('payments/:id/confirm')
  @HttpCode(200)
  @Idempotent()
  async confirm(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    return this.payments.confirm(id, req.user.userId);
  }

  @Post('payments/:id/cancel')
  @HttpCode(200)
  async cancel(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    return this.payments.cancel(id, req.user.userId);
  }

  @Post('payments/:id/dispute')
  @HttpCode(200)
  async dispute(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: DisputePaymentDto,
  ) {
    return this.payments.dispute(id, dto.reason, req.user.userId, dto.photoKeys ?? []);
  }

  @Post('payments/:id/resolve')
  @HttpCode(200)
  async resolve(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: ResolvePaymentDto,
  ) {
    return this.payments.resolve(id, {
      resolution: dto.resolution,
      adjustAmount: dto.adjustAmount,
      actorUserId: req.user.userId,
    });
  }

  @Get('projects/:projectId/payments')
  @RequireAccess({
    action: 'finance.budget.view',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async list(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Query('status') status?: PaymentStatus,
    @Query('kind') kind?: PaymentKind,
    @Query('userId') userId?: string,
  ) {
    const viewer = await this.buildProjectViewer(req.user.userId, projectId);
    return this.payments.listForProject(projectId, viewer, { status, kind, userId });
  }

  @Get('payments/:id')
  async get(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    const payment = await this.prisma.payment.findUnique({
      where: { id },
      select: { projectId: true },
    });
    if (!payment) {
      // Тонкий случай — пускаем сервис вернуть NotFoundError, чтобы не дублировать.
      return this.payments.get(id);
    }
    const viewer = await this.buildProjectViewer(req.user.userId, payment.projectId);
    return this.payments.get(id, viewer);
  }

  @Get('payments/:id/children')
  async children(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    const payment = await this.prisma.payment.findUnique({
      where: { id },
      select: { projectId: true },
    });
    const viewer = payment
      ? await this.buildProjectViewer(req.user.userId, payment.projectId)
      : { userId: req.user.userId };
    return this.payments.listChildren(id, viewer);
  }

  private async buildProjectViewer(userId: string, projectId: string) {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { ownerId: true },
    });
    const membership = await this.prisma.membership.findFirst({
      where: { projectId, userId },
      select: { role: true, permissions: true },
    });
    const perms = (membership?.permissions ?? {}) as { canSeeBudget?: boolean };
    return {
      userId,
      isOwner: project?.ownerId === userId,
      membershipRole: membership?.role as
        | 'customer'
        | 'representative'
        | 'foreman'
        | 'master'
        | undefined,
      canSeeBudget: perms.canSeeBudget === true,
    };
  }

  @Get('projects/:projectId/budget')
  @RequireAccess({
    action: 'finance.budget.view',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async projectBudget(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
  ) {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { ownerId: true },
    });
    const membership = await this.prisma.membership.findFirst({
      where: { projectId, userId: req.user.userId },
      select: { role: true, stageIds: true },
    });
    return this.budget.getProjectBudget(projectId, {
      userId: req.user.userId,
      isOwner: project?.ownerId === req.user.userId,
      membershipRole: membership?.role,
      assignedStageIds: membership?.stageIds ?? [],
    });
  }

  /**
   * P1.5: «Движение средств» — детальный money-flow для customer / representative.canSeeBudget.
   * advances + distributions + approved selfpurchases + material purchases + totals.
   */
  @Get('projects/:projectId/money-flow')
  @RequireAccess({
    action: 'finance.budget.view',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async moneyFlow(@Req() req: { user: AuthenticatedUser }, @Param('projectId') projectId: string) {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { ownerId: true },
    });
    const membership = await this.prisma.membership.findFirst({
      where: { projectId, userId: req.user.userId },
      select: { role: true, permissions: true, stageIds: true },
    });
    const perms = (membership?.permissions ?? {}) as { canSeeBudget?: boolean };
    return this.budget.getMoneyFlow(projectId, {
      userId: req.user.userId,
      isOwner: project?.ownerId === req.user.userId,
      membershipRole: membership?.role,
      assignedStageIds: membership?.stageIds ?? [],
      canSeeBudget: perms.canSeeBudget === true,
    });
  }

  @Get('stages/:stageId/budget')
  @RequireAccess({
    action: 'finance.budget.view',
    resource: 'stage',
    resourceIdFrom: { source: 'params', key: 'stageId' },
  })
  async stageBudget(@Req() req: { user: AuthenticatedUser }, @Param('stageId') stageId: string) {
    const stage = await this.prisma.stage.findUnique({
      where: { id: stageId },
      select: { projectId: true },
    });
    if (!stage) return null;
    const project = await this.prisma.project.findUnique({
      where: { id: stage.projectId },
      select: { ownerId: true },
    });
    const membership = await this.prisma.membership.findFirst({
      where: { projectId: stage.projectId, userId: req.user.userId },
      select: { role: true, stageIds: true },
    });
    return this.budget.getStageBudget(stageId, {
      userId: req.user.userId,
      isOwner: project?.ownerId === req.user.userId,
      membershipRole: membership?.role,
      assignedStageIds: membership?.stageIds ?? [],
    });
  }
}
