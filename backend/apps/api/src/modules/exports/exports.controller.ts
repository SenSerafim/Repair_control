import { Body, Controller, Get, Headers, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { Idempotent } from '../idempotency/idempotent.decorator';
import { ExportService } from './export.service';
import { CreateExportDto, ListFeedQueryDto } from './dto';

@ApiTags('feed-exports')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AccessGuard)
@Controller()
export class ExportsController {
  constructor(private readonly svc: ExportService) {}

  @Get('projects/:projectId/feed')
  @RequireAccess({
    action: 'chat.read', // любой member проекта — достаточно
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  listFeed(@Param('projectId') projectId: string, @Query() q: ListFeedQueryDto) {
    return this.svc.listFeed(projectId, {
      cursor: q.cursor,
      limit: q.limit,
      kind: q.kind,
      stageId: q.stageId,
      dateFrom: q.dateFrom,
      dateTo: q.dateTo,
      actorId: q.actorId,
    });
  }

  @Post('projects/:projectId/exports')
  @Idempotent()
  @RequireAccess({
    action: 'feed.export',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  create(
    @Param('projectId') projectId: string,
    @Body() dto: CreateExportDto,
    @Headers('idempotency-key') _idempotencyKey: string,
    @Req() req: any,
  ) {
    return this.svc.request(projectId, req.user.userId, dto.kind, {
      kind: dto.kinds,
      stageId: dto.stageId,
      dateFrom: dto.dateFrom,
      dateTo: dto.dateTo,
    });
  }

  @Get('exports/:id')
  @RequireAccess({ action: 'feed.export', resource: 'none' })
  get(@Param('id') id: string) {
    return this.svc.get(id);
  }

  @Get('projects/:projectId/exports')
  @RequireAccess({
    action: 'feed.export',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  list(@Param('projectId') projectId: string, @Req() req: any) {
    return this.svc.listForProject(projectId, req.user.userId);
  }
}
