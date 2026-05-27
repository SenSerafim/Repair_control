import { Body, Controller, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { StagesService } from './stages.service';
import {
  AssignForemanDto,
  AssignMasterDto,
  CreateStageDto,
  PauseStageDto,
  ReorderStagesDto,
  UpdateStageDto,
} from './dto';
import { AuthenticatedUser } from '../auth/jwt.strategy';

@ApiTags('stages')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller('projects/:projectId/stages')
export class StagesController {
  constructor(private readonly stages: StagesService) {}

  @Post()
  @RequireAccess({
    action: 'stage.manage',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async create(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Body() dto: CreateStageDto,
  ) {
    return this.stages.create({
      ...dto,
      projectId,
      actorUserId: req.user.userId,
      actorSystemRole: req.user.systemRole,
    });
  }

  /**
   * П1.11 / 4.8 — кнопка «Назначить бригадира» на этапе. RBAC: stage.manage
   * (только заказчик / представитель с canEditStages).
   */
  @Post(':stageId/assign-foreman')
  @RequireAccess({
    action: 'stage.manage',
    resource: 'stage',
    resourceIdFrom: { source: 'params', key: 'stageId' },
  })
  async assignForeman(
    @Req() req: { user: AuthenticatedUser },
    @Param('stageId') stageId: string,
    @Body() dto: AssignForemanDto,
  ) {
    return this.stages.assignForeman(stageId, dto.userId, req.user.userId);
  }

  /**
   * П2.5 / 7.5 — кнопка «Назначить мастера» на этапе. Доступна бригадиру этапа,
   * заказчику и представителю с canEditStages. Точная проверка — на уровне сервиса.
   */
  @Post(':stageId/assign-master')
  @RequireAccess({
    action: 'stage.manage',
    resource: 'stage',
    resourceIdFrom: { source: 'params', key: 'stageId' },
  })
  async assignMaster(
    @Req() req: { user: AuthenticatedUser },
    @Param('stageId') stageId: string,
    @Body() dto: AssignMasterDto,
  ) {
    return this.stages.assignMaster(stageId, dto.userId ?? null, req.user.userId);
  }

  @Get()
  async list(@Param('projectId') projectId: string) {
    return this.stages.listForProject(projectId);
  }

  @Get(':stageId')
  async get(@Param('stageId') stageId: string) {
    return this.stages.get(stageId);
  }

  // ВАЖНО: статический маршрут 'reorder' объявлен ДО динамического ':stageId',
  // иначе express-роутер NestJS подхватит PATCH /stages/reorder как
  // update(stageId='reorder') — AccessGuard вызовет hydrateStageContext
  // с несуществующим id, membership/owner не подтянутся, и RBAC вернёт 403.
  @Patch('reorder')
  @RequireAccess({
    action: 'stage.manage',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async reorder(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Body() dto: ReorderStagesDto,
  ) {
    return this.stages.reorder(projectId, dto.items, req.user.userId);
  }

  @Patch(':stageId')
  @RequireAccess({
    action: 'stage.manage',
    resource: 'stage',
    resourceIdFrom: { source: 'params', key: 'stageId' },
  })
  async update(
    @Req() req: { user: AuthenticatedUser },
    @Param('stageId') stageId: string,
    @Body() dto: UpdateStageDto,
  ) {
    return this.stages.update(stageId, { ...dto, actorUserId: req.user.userId });
  }

  @Post(':stageId/start')
  @RequireAccess({
    action: 'stage.start',
    resource: 'stage',
    resourceIdFrom: { source: 'params', key: 'stageId' },
  })
  async start(@Req() req: { user: AuthenticatedUser }, @Param('stageId') stageId: string) {
    return this.stages.start(stageId, req.user.userId);
  }

  @Post(':stageId/pause')
  @RequireAccess({
    action: 'stage.pause',
    resource: 'stage',
    resourceIdFrom: { source: 'params', key: 'stageId' },
  })
  async pause(
    @Req() req: { user: AuthenticatedUser },
    @Param('stageId') stageId: string,
    @Body() dto: PauseStageDto,
  ) {
    return this.stages.pause(stageId, req.user.userId, dto.reason, dto.comment);
  }

  @Post(':stageId/resume')
  @RequireAccess({
    action: 'stage.pause',
    resource: 'stage',
    resourceIdFrom: { source: 'params', key: 'stageId' },
  })
  async resume(@Req() req: { user: AuthenticatedUser }, @Param('stageId') stageId: string) {
    return this.stages.resume(stageId, req.user.userId);
  }

  @Post(':stageId/send-to-review')
  @RequireAccess({
    action: 'stage.manage',
    resource: 'stage',
    resourceIdFrom: { source: 'params', key: 'stageId' },
  })
  async sendToReview(@Req() req: { user: AuthenticatedUser }, @Param('stageId') stageId: string) {
    return this.stages.sendToReview(stageId, req.user.userId);
  }

  /**
   * П2.3 / 4.2 — «Отправить план на согласование заказчику».
   *
   * Доступно бригадиру (или представителю с canEditStages — оба покрываются
   * правом `stage.manage`). Мастер блокируется внутри ApprovalsService.validate
   * — у нас нет отдельной guard-action на это (план семантически = `stage.manage`
   * + scope=plan). Endpoint идемпотентный: повторный вызов возвращает уже
   * существующий pending plan-approval для этого этапа.
   */
  @Post(':stageId/submit-plan')
  @RequireAccess({
    action: 'stage.manage',
    resource: 'stage',
    resourceIdFrom: { source: 'params', key: 'stageId' },
  })
  async submitPlan(@Req() req: { user: AuthenticatedUser }, @Param('stageId') stageId: string) {
    return this.stages.submitPlan(stageId, req.user.userId);
  }
}
