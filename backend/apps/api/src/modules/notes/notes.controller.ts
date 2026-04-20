import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { NotesService } from './notes.service';
import { CreateNoteDto, UpdateNoteDto } from './dto';

@ApiTags('notes')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller()
export class NotesController {
  constructor(private readonly notes: NotesService) {}

  @Post('projects/:projectId/notes')
  @RequireAccess({
    action: 'note.manage',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async create(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Body() dto: CreateNoteDto,
  ) {
    return this.notes.create({
      projectId,
      authorId: req.user.userId,
      scope: dto.scope,
      text: dto.text,
      addresseeId: dto.addresseeId,
      stageId: dto.stageId,
    });
  }

  @Get('projects/:projectId/notes')
  @RequireAccess({
    action: 'note.manage',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async list(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Query('scope') scope?: 'personal' | 'for_me' | 'stage',
    @Query('stageId') stageId?: string,
    @Query('search') search?: string,
  ) {
    return this.notes.list({
      userId: req.user.userId,
      projectId,
      scope,
      stageId,
      search,
    });
  }

  @Patch('notes/:noteId')
  async update(
    @Req() req: { user: AuthenticatedUser },
    @Param('noteId') noteId: string,
    @Body() dto: UpdateNoteDto,
  ) {
    return this.notes.update(noteId, dto.text, req.user.userId);
  }

  @Delete('notes/:noteId')
  @HttpCode(204)
  async delete(@Req() req: { user: AuthenticatedUser }, @Param('noteId') noteId: string) {
    await this.notes.delete(noteId, req.user.userId);
  }
}
