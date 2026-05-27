import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { ToolsService } from './tools.service';
import {
  AttachToolsToProjectDto,
  ClaimToolDto,
  CreateProjectToolDto,
  CreateToolDto,
  UpdateToolDto,
} from './dto';

@ApiTags('tools')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller()
export class ToolsController {
  constructor(private readonly tools: ToolsService) {}

  // ---------- My Tools (профиль пользователя) ----------

  @Post('me/tools')
  async createMine(@Req() req: { user: AuthenticatedUser }, @Body() dto: CreateToolDto) {
    return this.tools.createMyTool({
      ownerId: req.user.userId,
      name: dto.name,
      photoKey: dto.photoKey,
      serial: dto.serial,
    });
  }

  @Get('me/tools')
  async listMine(@Req() req: { user: AuthenticatedUser }) {
    return this.tools.listMyTools(req.user.userId);
  }

  @Get('tools/:id')
  async get(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    return this.tools.getTool(id, req.user.userId);
  }

  @Patch('tools/:id')
  async update(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: UpdateToolDto,
  ) {
    return this.tools.updateTool(id, dto, req.user.userId);
  }

  @Delete('tools/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string): Promise<void> {
    await this.tools.deleteTool(id, req.user.userId);
  }

  // ---------- Project Tools ----------

  /**
   * Список инструментов проекта (виден всем member-ам).
   */
  @Get('projects/:projectId/tools')
  @RequireAccess({
    action: 'tools.view_project',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async listProject(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
  ) {
    return this.tools.listProjectTools(projectId, req.user.userId);
  }

  /**
   * Создать новый инструмент сразу в проекте. Любой member.
   */
  @Post('projects/:projectId/tools')
  @RequireAccess({
    action: 'tools.add_to_project',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async createInProject(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Body() dto: CreateProjectToolDto,
  ) {
    return this.tools.createInProject({
      projectId,
      actorUserId: req.user.userId,
      ownerId: dto.ownerId,
      name: dto.name,
      photoKey: dto.photoKey,
      serial: dto.serial,
    });
  }

  /**
   * Bulk attach «из Моих инструментов» в проект.
   */
  @Post('projects/:projectId/tools/attach')
  @RequireAccess({
    action: 'tools.add_to_project',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async attachFromMy(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Body() dto: AttachToolsToProjectDto,
  ) {
    return this.tools.attachFromMy(projectId, dto.toolItemIds, req.user.userId);
  }

  /**
   * Открепить инструмент от проекта (только owner).
   */
  @Delete('projects/:projectId/tools/:toolId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async detachFromProject(
    @Req() req: { user: AuthenticatedUser },
    @Param('toolId') toolId: string,
  ): Promise<void> {
    await this.tools.detachFromProject(toolId, req.user.userId);
  }

  // ---------- Custody ----------

  /**
   * Self-claim: текущий пользователь отмечает «инструмент теперь у меня».
   */
  @Post('tools/:id/claim')
  @HttpCode(HttpStatus.OK)
  async claim(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: ClaimToolDto,
  ) {
    return this.tools.claim(id, req.user.userId, dto.note);
  }

  /**
   * История передач инструмента (timeline).
   */
  @Get('tools/:id/custody-history')
  async history(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    return this.tools.listCustodyHistory(id, req.user.userId);
  }
}
