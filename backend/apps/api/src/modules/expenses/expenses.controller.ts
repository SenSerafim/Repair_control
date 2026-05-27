import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { CreateExpenseDto, type ExpenseCategoryLike } from './dto';
import { ExpensesService } from './expenses.service';

/**
 * ТЗ NEWFIX §5: REST для расходов проекта/этапа. RBAC reuse'нем
 * `finance.budget_view` для GET (виден всем, кто видит бюджет) и
 * `finance.payment_create` для POST (создавать может бригадир/заказчик).
 */
@ApiTags('expenses')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller()
export class ExpensesController {
  constructor(private readonly expenses: ExpensesService) {}

  @Post('projects/:projectId/expenses')
  @RequireAccess({
    // ТЗ NEWFIX §5: расход может зафиксировать любой member-of-project,
    // у которого есть право видеть бюджет (бригадир, заказчик-владелец,
    // представитель с canSeeBudget, мастер). Авансовая логика
    // (finance.payment.create_advance) сюда не подходит — это просто
    // запись траты, без перевода денег между сторонами.
    action: 'finance.budget.view',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async create(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Body() dto: CreateExpenseDto,
  ) {
    return this.expenses.create({
      projectId,
      createdById: req.user.userId,
      category: dto.category,
      name: dto.name,
      amount: dto.amount,
      stageId: dto.stageId,
      comment: dto.comment,
      photoKey: dto.photoKey,
    });
  }

  @Get('projects/:projectId/expenses')
  @RequireAccess({
    action: 'finance.budget.view',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async list(
    @Param('projectId') projectId: string,
    @Query('stageId') stageId?: string,
    @Query('category') category?: ExpenseCategoryLike,
  ) {
    return this.expenses.listForProject(projectId, { stageId, category });
  }
}
