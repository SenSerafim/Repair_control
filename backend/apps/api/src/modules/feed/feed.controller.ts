import {
  BadRequestException,
  Controller,
  Get,
  Header,
  Param,
  Query,
  Req,
  Res,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { PrismaService } from '@app/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { FeedPeriodPdfService } from './feed-period-pdf.service';
import { FeedService, FeedViewer } from './feed.service';

/**
 * ТЗ NEWFIX §12: REST ленты + PDF за период. GET-эндпоинт ленты
 * выносим из неявного in-process использования (раньше mobile фид
 * тянулся другим маршрутом) и принимаем `from`/`to` для фильтра.
 */
@ApiTags('feed')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller('projects/:projectId/feed')
export class FeedController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
    private readonly pdf: FeedPeriodPdfService,
  ) {}

  @Get()
  @RequireAccess({
    // approval.list разрешает любому активному участнику проекта;
    // ленту видят все, кто видит проект.
    action: 'approval.list',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  async list(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
    @Query('limit') limit?: string,
  ) {
    const viewer = await this.buildViewer(req.user.userId, projectId);
    const items = await this.feed.listForProject(projectId, viewer, {
      from: parseDate(dateFrom),
      to: parseDate(dateTo),
      limit: limit ? Math.min(Number(limit), 500) : undefined,
    });
    // Mobile FeedRepository умеет и Map ({items,nextCursor}), и плоский
    // массив — отдаём Map, чтобы оставить место под cursor-pagination
    // в будущем без breaking change.
    return { items, nextCursor: null };
  }

  @Get('pdf')
  @RequireAccess({
    // approval.list разрешает любому активному участнику проекта;
    // ленту видят все, кто видит проект.
    action: 'approval.list',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  @Header('Content-Type', 'application/pdf')
  async exportPdf(
    @Req() req: { user: AuthenticatedUser },
    @Param('projectId') projectId: string,
    @Query('dateFrom') dateFrom: string,
    @Query('dateTo') dateTo: string,
    @Res({ passthrough: false }) res: Response,
  ) {
    const fromD = parseDate(dateFrom);
    const toD = parseDate(dateTo);
    if (!fromD || !toD) {
      throw new BadRequestException('dateFrom_and_dateTo_required');
    }
    const viewer = await this.buildViewer(req.user.userId, projectId);
    const buffer = await this.pdf.render(projectId, viewer, {
      from: fromD,
      to: toD,
    });
    res.setHeader(
      'Content-Disposition',
      `inline; filename="feed-${projectId}-${formatDate(fromD)}-${formatDate(toD)}.pdf"`,
    );
    res.setHeader('Content-Length', buffer.length.toString());
    res.end(buffer);
  }

  private async buildViewer(userId: string, projectId: string): Promise<FeedViewer> {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: {
        ownerId: true,
        memberships: {
          where: { userId, removedAt: null },
          select: { role: true, stageIds: true },
        },
        stages: { select: { id: true, foremanIds: true } },
      },
    });
    const isOwner = project?.ownerId === userId;
    const m = project?.memberships[0];
    const membershipRole = (m?.role ?? undefined) as FeedViewer['membershipRole'];
    const assignedStageIds = m?.stageIds ?? [];
    const foremanStageIds = (project?.stages ?? [])
      .filter((s) => (s.foremanIds ?? []).includes(userId))
      .map((s) => s.id);
    return {
      userId,
      isOwner,
      membershipRole,
      assignedStageIds,
      foremanStageIds,
    };
  }
}

function parseDate(raw?: string): Date | undefined {
  if (!raw) return undefined;
  const d = new Date(raw);
  if (Number.isNaN(d.getTime())) return undefined;
  return d;
}

function formatDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}
