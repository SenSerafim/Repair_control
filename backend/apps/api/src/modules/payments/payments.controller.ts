import { Body, Controller, Get, Headers, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { PaymentKind } from '@prisma/client';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { Idempotent } from '../idempotency/idempotent.decorator';
import { PaymentsService } from './payments.service';
import { BudgetCalculator } from './budget-calculator';
import { CreateAdvanceDto, DistributeDto } from './dto';
import { ErrorCodes, InvalidInputError, PrismaService } from '@app/common';

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
    action: 'finance.payment.create_advance',
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
  @RequireAccess({
    action: 'finance.payment.distribute',
    resource: 'payment',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
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

  /**
   * Простая выплата мастеру из «кассы бригадира». Не требует выбора конкретного
   * родительского аванса — баланс кассы считается агрегатом (advancesReceived −
   * distributed). Точка входа на BudgetScreen у бригадира.
   */
  @Post('projects/:projectId/payments/distribute')
  @Idempotent()
  @RequireAccess({
    action: 'finance.payment.distribute',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async distributeFromWallet(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Headers('idempotency-key') idempotencyKey: string,
    @Body() dto: DistributeDto,
  ) {
    return this.payments.createDistribution({
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

  @Get('projects/:projectId/payments')
  @RequireAccess({
    action: 'finance.budget.view',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async list(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Query('kind') kind?: PaymentKind,
    @Query('userId') userId?: string,
  ) {
    const viewer = await this.buildProjectViewer(req.user.userId, projectId);
    return this.payments.listForProject(projectId, viewer, { kind, userId });
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
    // 2026-05: явно фильтруем removedAt=null и приоритезируем role при множественном membership.
    // Customer > representative > foreman > master — чтобы owner-customer с legacy
    // foreman-записью не получал foreman-срез и не видел нули в шапке.
    const memberships = await this.prisma.membership.findMany({
      where: { projectId, userId: req.user.userId, removedAt: null },
      select: { role: true, stageIds: true, permissions: true },
    });
    const rolePriority: Record<string, number> = {
      customer: 0,
      representative: 1,
      foreman: 2,
      master: 3,
    };
    const membership = memberships
      .slice()
      .sort((a, b) => (rolePriority[a.role] ?? 9) - (rolePriority[b.role] ?? 9))[0];
    const perms = (membership?.permissions ?? {}) as { canSeeBudget?: boolean };
    return this.budget.getProjectBudget(projectId, {
      userId: req.user.userId,
      isOwner: project?.ownerId === req.user.userId,
      membershipRole: membership?.role,
      assignedStageIds: membership?.stageIds ?? [],
      canSeeBudget: perms.canSeeBudget === true,
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
  async moneyFlow(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { ownerId: true },
    });
    const memberships = await this.prisma.membership.findMany({
      where: { projectId, userId: req.user.userId, removedAt: null },
      select: { role: true, permissions: true, stageIds: true },
    });
    const rolePriorityMF: Record<string, number> = {
      customer: 0,
      representative: 1,
      foreman: 2,
      master: 3,
    };
    const membership = memberships
      .slice()
      .sort((a, b) => (rolePriorityMF[a.role] ?? 9) - (rolePriorityMF[b.role] ?? 9))[0];
    const perms = (membership?.permissions ?? {}) as { canSeeBudget?: boolean };
    const range = this.parseDateRange(from, to);
    return this.budget.getMoneyFlow(
      projectId,
      {
        userId: req.user.userId,
        isOwner: project?.ownerId === req.user.userId,
        membershipRole: membership?.role,
        assignedStageIds: membership?.stageIds ?? [],
        canSeeBudget: perms.canSeeBudget === true,
      },
      range,
    );
  }

  private parseDateRange(from?: string, to?: string): { from?: Date; to?: Date } | undefined {
    if (!from && !to) return undefined;
    const f = from ? new Date(from) : undefined;
    const t = to ? new Date(to) : undefined;
    if (f && Number.isNaN(f.getTime())) {
      throw new InvalidInputError(
        ErrorCodes.INVALID_INPUT,
        'invalid `from` date — expect ISO 8601',
      );
    }
    if (t && Number.isNaN(t.getTime())) {
      throw new InvalidInputError(ErrorCodes.INVALID_INPUT, 'invalid `to` date — expect ISO 8601');
    }
    if (f && t && f.getTime() > t.getTime()) {
      throw new InvalidInputError(ErrorCodes.INVALID_INPUT, '`from` must be ≤ `to`');
    }
    return { from: f, to: t };
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
