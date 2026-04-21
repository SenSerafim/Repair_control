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
  Res,
  UseGuards,
} from '@nestjs/common';
import { Response } from 'express';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { MethodologyService } from './methodology.service';
import { CreateArticleDto, CreateSectionDto, UpdateArticleDto, UpdateSectionDto } from './dto';

@ApiTags('methodology')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller()
export class MethodologyController {
  constructor(private readonly svc: MethodologyService) {}

  // ---- Public (read) ----

  @Get('methodology/sections')
  @RequireAccess({ action: 'methodology.read' })
  async listSections() {
    return this.svc.listSections();
  }

  @Get('methodology/sections/:id')
  @RequireAccess({ action: 'methodology.read' })
  async getSection(@Param('id') id: string) {
    return this.svc.getSection(id);
  }

  @Get('methodology/articles/:id')
  @RequireAccess({ action: 'methodology.read' })
  async getArticle(
    @Req() req: { headers: Record<string, string> },
    @Param('id') id: string,
    @Res({ passthrough: true }) res: Response,
  ) {
    const a = await this.svc.getArticle(id);
    const ifNoneMatch = req.headers['if-none-match'];
    if (ifNoneMatch && ifNoneMatch === a.etag) {
      res.status(304);
      return undefined;
    }
    res.setHeader('ETag', a.etag);
    return a;
  }

  @Get('methodology/search')
  @RequireAccess({ action: 'methodology.read' })
  async search(@Query('q') q: string, @Query('limit') limit?: string) {
    const n = limit ? parseInt(limit, 10) : 20;
    return { hits: await this.svc.search(q, Number.isFinite(n) && n > 0 ? Math.min(n, 100) : 20) };
  }

  // ---- Admin ----

  @Post('admin/methodology/sections')
  @RequireAccess({ action: 'methodology.edit' })
  async createSection(@Req() req: { user: AuthenticatedUser }, @Body() dto: CreateSectionDto) {
    return this.svc.createSection({ ...dto, actorUserId: req.user.userId });
  }

  @Patch('admin/methodology/sections/:id')
  @RequireAccess({ action: 'methodology.edit' })
  async updateSection(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: UpdateSectionDto,
  ) {
    return this.svc.updateSection(id, { ...dto, actorUserId: req.user.userId });
  }

  @Delete('admin/methodology/sections/:id')
  @HttpCode(204)
  @RequireAccess({ action: 'methodology.edit' })
  async deleteSection(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    await this.svc.deleteSection(id, req.user.userId);
  }

  @Post('admin/methodology/sections/:sectionId/articles')
  @RequireAccess({ action: 'methodology.edit' })
  async createArticle(
    @Req() req: { user: AuthenticatedUser },
    @Param('sectionId') sectionId: string,
    @Body() dto: CreateArticleDto,
  ) {
    return this.svc.createArticle({ ...dto, sectionId, actorUserId: req.user.userId });
  }

  @Patch('admin/methodology/articles/:id')
  @RequireAccess({ action: 'methodology.edit' })
  async updateArticle(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: UpdateArticleDto,
  ) {
    return this.svc.updateArticle(id, { ...dto, actorUserId: req.user.userId });
  }

  @Delete('admin/methodology/articles/:id')
  @HttpCode(204)
  @RequireAccess({ action: 'methodology.edit' })
  async deleteArticle(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    await this.svc.deleteArticle(id, req.user.userId);
  }
}
