import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { MaterialsService } from './materials.service';
import { CreateMaterialRequestDto } from './dto';

@ApiTags('materials')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller()
export class MaterialsController {
  constructor(private readonly materials: MaterialsService) {}

  /**
   * Создать заявку. customer-owner / representative.canApprove → сразу «Согласовано» (`open`).
   * foreman / master → «Ждёт согласования» + Approval(material_purchase) заказчику.
   */
  @Post('projects/:projectId/materials')
  @RequireAccess({
    action: 'materials.manage',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async create(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Body() dto: CreateMaterialRequestDto,
  ) {
    return this.materials.createRequest({
      projectId,
      stageId: dto.stageId,
      recipient: dto.recipient,
      title: dto.title,
      comment: dto.comment,
      items: dto.items,
      actorUserId: req.user.userId,
    });
  }

  @Get('projects/:projectId/materials')
  @RequireAccess({
    action: 'materials.manage',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async list(
    @Param('projectId') projectId: string,
    @Query('status') status?: string,
    @Query('stageId') stageId?: string,
  ) {
    return this.materials.listForProject(projectId, { status, stageId });
  }

  @Get('materials/:id')
  async get(@Param('id') id: string) {
    return this.materials.get(id);
  }
}
