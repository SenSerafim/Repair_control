import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { Idempotent } from '../idempotency/idempotent.decorator';
import { MaterialsService } from './materials.service';
import {
  CreateMaterialRequestDto,
  DisputeMaterialDto,
  MarkBoughtDto,
  ResolveMaterialDto,
} from './dto';

@ApiTags('materials')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller()
export class MaterialsController {
  constructor(private readonly materials: MaterialsService) {}

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

  @Post('materials/:id/send')
  @HttpCode(200)
  async send(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    return this.materials.send(id, req.user.userId);
  }

  @Post('materials/:id/items/:itemId/bought')
  @HttpCode(200)
  async markBought(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') _id: string,
    @Param('itemId') itemId: string,
    @Body() dto: MarkBoughtDto,
  ) {
    return this.materials.markItemBought(itemId, dto, req.user.userId);
  }

  @Post('materials/:id/finalize')
  @HttpCode(200)
  @Idempotent()
  @RequireAccess({
    action: 'material.finalize',
    resource: 'material_request',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  async finalize(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    return this.materials.finalize(id, req.user.userId);
  }

  @Post('materials/:id/confirm-delivery')
  @HttpCode(200)
  async confirmDelivery(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    return this.materials.confirmDelivery(id, req.user.userId);
  }

  @Post('materials/:id/dispute')
  @HttpCode(200)
  async dispute(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: DisputeMaterialDto,
  ) {
    return this.materials.dispute(id, dto.reason, req.user.userId);
  }

  @Post('materials/:id/resolve')
  @HttpCode(200)
  async resolve(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: ResolveMaterialDto,
  ) {
    return this.materials.resolve(id, { resolution: dto.resolution, actorUserId: req.user.userId });
  }
}
