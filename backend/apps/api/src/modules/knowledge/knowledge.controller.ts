import {
  Controller,
  Get,
  Headers,
  NotFoundException,
  Param,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import type { Response } from 'express';
import { KnowledgeCategoryScope } from '@prisma/client';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { KnowledgeService } from './knowledge.service';
import { KnowledgeSearchService } from './knowledge-search.service';

@ApiTags('knowledge')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AccessGuard)
@Controller('knowledge')
export class KnowledgeController {
  constructor(
    private readonly svc: KnowledgeService,
    private readonly search: KnowledgeSearchService,
  ) {}

  @Get('categories')
  @RequireAccess({ action: 'knowledge.read', resource: 'none' })
  listCategories(
    @Query('scope') scope?: KnowledgeCategoryScope,
    @Query('moduleSlug') moduleSlug?: string,
  ) {
    return this.svc.listCategories({ scope, moduleSlug });
  }

  @Get('categories/:id')
  @RequireAccess({ action: 'knowledge.read', resource: 'none' })
  getCategory(@Param('id') id: string) {
    return this.svc.getCategoryWithArticles(id);
  }

  @Get('articles/:id')
  @RequireAccess({ action: 'knowledge.read', resource: 'none' })
  async getArticle(
    @Param('id') id: string,
    @Headers('if-none-match') ifNoneMatch: string | undefined,
    @Res() res: Response,
  ) {
    const article = await this.svc.getArticle(id);
    const etag = `"${article.etag}"`;
    if (ifNoneMatch && ifNoneMatch.replace(/^W\//, '').trim() === etag) {
      // RFC 7232: 304 ответ ДОЛЖЕН быть с пустым телом (не application/json {}).
      res.status(304).end();
      return;
    }
    res.setHeader('ETag', etag);
    res.json(article);
  }

  @Get('articles/:articleId/assets/:assetId/url')
  @RequireAccess({ action: 'knowledge.read', resource: 'none' })
  async assetUrl(@Param('articleId') articleId: string, @Param('assetId') assetId: string) {
    return this.svc.getAssetDownloadUrl(articleId, assetId);
  }

  @Get('search')
  @RequireAccess({ action: 'knowledge.read', resource: 'none' })
  async searchArticles(
    @Query('q') q: string,
    @Query('limit') limit?: string,
    @Query('scope') scope?: string,
    @Query('moduleSlug') moduleSlug?: string,
  ) {
    if (!q) throw new NotFoundException('q is required');
    const hits = await this.search.search({
      q,
      limit: limit ? Number(limit) : undefined,
      scope,
      moduleSlug,
    });
    return { hits };
  }
}
