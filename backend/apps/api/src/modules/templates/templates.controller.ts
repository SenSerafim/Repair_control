import { Body, Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { TemplatesService } from './templates.service';
import { CreateStageFromTemplateDto, SaveAsTemplateDto } from '../stages/dto';
import { AuthenticatedUser } from '../auth/jwt.strategy';

@ApiTags('templates')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('templates')
export class TemplatesController {
  constructor(private readonly templates: TemplatesService) {}

  @Get('platform')
  async platform() {
    return this.templates.listPlatform();
  }

  @Get('user')
  async user(@Req() req: { user: AuthenticatedUser }) {
    return this.templates.listUser(req.user.userId);
  }

  @Get(':id')
  async get(@Param('id') id: string) {
    return this.templates.get(id);
  }

  @Post(':templateId/apply')
  async apply(
    @Req() req: { user: AuthenticatedUser },
    @Param('templateId') templateId: string,
    @Body() dto: CreateStageFromTemplateDto,
  ) {
    return this.templates.applyToProject({
      templateId,
      projectId: dto.projectId,
      actorUserId: req.user.userId,
      plannedStart: dto.plannedStart,
      plannedEnd: dto.plannedEnd,
    });
  }

  @Post('from-stage/:stageId')
  async saveFromStage(
    @Req() req: { user: AuthenticatedUser },
    @Param('stageId') stageId: string,
    @Body() dto: SaveAsTemplateDto,
  ) {
    return this.templates.createFromStage({
      stageId,
      authorId: req.user.userId,
      title: dto.title,
    });
  }
}
