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
import { PrismaService } from '@app/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { ToolsService } from './tools.service';
import {
  AddToolsToProjectDto,
  CreateToolDto,
  IssueToolDto,
  RejectRequestDto,
  RequestToolDto,
  ReturnToolDto,
  UpdateToolDto,
} from './dto';

@ApiTags('tools')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller()
export class ToolsController {
  constructor(
    private readonly tools: ToolsService,
    private readonly prisma: PrismaService,
  ) {}

  // ---- /me/tools ----

  @Post('me/tools')
  async create(@Req() req: { user: AuthenticatedUser }, @Body() dto: CreateToolDto) {
    return this.tools.createToolItem({ ownerId: req.user.userId, ...dto });
  }

  @Get('me/tools')
  async listMine(@Req() req: { user: AuthenticatedUser }) {
    return this.tools.listOwn(req.user.userId);
  }

  @Patch('tools/:id')
  async update(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: UpdateToolDto,
  ) {
    return this.tools.updateToolItem(id, dto, req.user.userId);
  }

  @Get('tools/:id')
  async get(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    return this.tools.getTool(id, req.user.userId);
  }

  @Delete('tools/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string): Promise<void> {
    await this.tools.deleteToolItem(id, req.user.userId);
  }

  // ---- /projects/:projectId/tool-issuances ----

  @Post('projects/:projectId/tool-issuances')
  @RequireAccess({
    action: 'tools.issue',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async issue(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Body() dto: IssueToolDto,
  ) {
    return this.tools.issue({
      toolItemId: dto.toolItemId,
      projectId,
      stageId: dto.stageId,
      toUserId: dto.toUserId,
      qty: dto.qty,
      actorUserId: req.user.userId,
    });
  }

  @Get('projects/:projectId/tool-issuances')
  @RequireAccess({
    action: 'tools.manage',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async list(@Req() req: { user: AuthenticatedUser }, @Param('projectId') projectId: string) {
    const membership = await this.prisma.membership.findFirst({
      where: { projectId, userId: req.user.userId },
      select: { role: true },
    });
    return this.tools.listIssuancesForProject(projectId, req.user.userId, membership?.role);
  }

  @Post('tool-issuances/:id/confirm')
  @HttpCode(200)
  @RequireAccess({
    action: 'tools.manage',
    resource: 'tool_issuance',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  async confirmReceipt(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    return this.tools.confirmReceipt(id, req.user.userId);
  }

  @Post('tool-issuances/:id/return')
  @HttpCode(200)
  @RequireAccess({
    action: 'tools.return',
    resource: 'tool_issuance',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  async requestReturn(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: ReturnToolDto,
  ) {
    return this.tools.requestReturn(id, dto.returnedQty, req.user.userId);
  }

  @Post('tool-issuances/:id/return-confirm')
  @HttpCode(200)
  @RequireAccess({
    action: 'tools.return',
    resource: 'tool_issuance',
    resourceIdFrom: { source: 'params', key: 'id' },
  })
  async confirmReturn(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    return this.tools.confirmReturn(id, req.user.userId);
  }

  // ---- П2.15: реестр + заявки на инструмент ----

  /**
   * Реестр инструментов проекта (виден всем участникам — П2.15).
   * Используется на mobile в новой вкладке «Инструменты».
   */
  @Get('projects/:projectId/tool-registry')
  async registry(@Param('projectId') projectId: string) {
    return this.tools.listProjectRegistry(projectId);
  }

  /**
   * Bulk-add «из моих инструментов в проект» (П2.15 / П3.2).
   */
  @Post('projects/:projectId/tools/from-my')
  async addFromMy(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Body() dto: AddToolsToProjectDto,
  ) {
    const result: unknown[] = [];
    for (const id of dto.toolItemIds) {
      result.push(await this.tools.addToProject(id, projectId, req.user.userId));
    }
    return result;
  }

  /**
   * Заявка на получение инструмента (П2.15). Доступно любому участнику проекта,
   * у которого нет инструмента (валидируется в сервисе через ownerId !== byUserId).
   */
  @Post('tool-requests')
  async requestTool(@Req() req: { user: AuthenticatedUser }, @Body() dto: RequestToolDto) {
    return this.tools.requestTool({
      toolItemId: dto.toolItemId,
      byUserId: req.user.userId,
      qty: dto.qty,
      stageId: dto.stageId,
    });
  }

  @Post('tool-requests/:id/approve')
  @HttpCode(200)
  async approveRequest(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    return this.tools.approveRequest(id, req.user.userId);
  }

  @Post('tool-requests/:id/reject')
  @HttpCode(200)
  async rejectRequest(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: RejectRequestDto,
  ) {
    return this.tools.rejectRequest(id, req.user.userId, dto.comment);
  }
}
