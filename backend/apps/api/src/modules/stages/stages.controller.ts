import { Body, Controller, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { StagesService } from './stages.service';
import { CreateStageDto, PauseStageDto, ReorderStagesDto, UpdateStageDto } from './dto';
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
    return this.stages.create({ ...dto, projectId, actorUserId: req.user.userId });
  }

  @Get()
  async list(@Param('projectId') projectId: string) {
    return this.stages.listForProject(projectId);
  }

  @Get(':stageId')
  async get(@Param('stageId') stageId: string) {
    return this.stages.get(stageId);
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
}
