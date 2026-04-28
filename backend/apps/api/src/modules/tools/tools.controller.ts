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
import { CreateToolDto, IssueToolDto, ReturnToolDto, UpdateToolDto } from './dto';

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
}
