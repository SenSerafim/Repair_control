import { Body, Controller, Delete, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { KnowledgeService } from './knowledge.service';
import {
  ConfirmKnowledgeAssetDto,
  CreateKnowledgeArticleDto,
  CreateKnowledgeCategoryDto,
  SetAssetThumbnailDto,
  UpdateKnowledgeArticleDto,
  UpdateKnowledgeCategoryDto,
} from './dto';

@ApiTags('admin-knowledge')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AccessGuard)
@Controller('admin/knowledge')
export class KnowledgeAdminController {
  constructor(private readonly svc: KnowledgeService) {}

  // ---- Categories ----

  @Get('categories')
  @RequireAccess({ action: 'admin.knowledge.manage', resource: 'none' })
  listCategories() {
    return this.svc.listAllCategories();
  }

  @Post('categories')
  @RequireAccess({ action: 'admin.knowledge.manage', resource: 'none' })
  createCategory(@Body() dto: CreateKnowledgeCategoryDto, @Req() req: any) {
    return this.svc.createCategory(req.user.userId, dto);
  }

  @Patch('categories/:id')
  @RequireAccess({ action: 'admin.knowledge.manage', resource: 'none' })
  updateCategory(
    @Param('id') id: string,
    @Body() dto: UpdateKnowledgeCategoryDto,
    @Req() req: any,
  ) {
    return this.svc.updateCategory(id, req.user.userId, dto);
  }

  @Delete('categories/:id')
  @RequireAccess({ action: 'admin.knowledge.manage', resource: 'none' })
  async deleteCategory(@Param('id') id: string, @Req() req: any) {
    await this.svc.deleteCategory(id, req.user.userId);
    return { id };
  }

  // ---- Articles ----

  @Post('articles')
  @RequireAccess({ action: 'admin.knowledge.manage', resource: 'none' })
  createArticle(@Body() dto: CreateKnowledgeArticleDto, @Req() req: any) {
    return this.svc.createArticle(req.user.userId, dto);
  }

  @Patch('articles/:id')
  @RequireAccess({ action: 'admin.knowledge.manage', resource: 'none' })
  updateArticle(@Param('id') id: string, @Body() dto: UpdateKnowledgeArticleDto, @Req() req: any) {
    return this.svc.updateArticle(id, req.user.userId, dto);
  }

  @Delete('articles/:id')
  @RequireAccess({ action: 'admin.knowledge.manage', resource: 'none' })
  async deleteArticle(@Param('id') id: string, @Req() req: any) {
    await this.svc.deleteArticle(id, req.user.userId);
    return { id };
  }

  // ---- Assets ----

  @Post('articles/:articleId/assets')
  @RequireAccess({ action: 'admin.knowledge.manage', resource: 'none' })
  confirmAsset(
    @Param('articleId') articleId: string,
    @Body() dto: ConfirmKnowledgeAssetDto,
    @Req() req: any,
  ) {
    return this.svc.confirmAsset(articleId, req.user.userId, dto);
  }

  @Post('articles/:articleId/assets/:assetId/thumbnail')
  @RequireAccess({ action: 'admin.knowledge.manage', resource: 'none' })
  setAssetThumbnail(
    @Param('articleId') articleId: string,
    @Param('assetId') assetId: string,
    @Body() dto: SetAssetThumbnailDto,
    @Req() req: any,
  ) {
    return this.svc.setAssetThumbnail(articleId, assetId, req.user.userId, dto);
  }

  @Delete('articles/:articleId/assets/:assetId')
  @RequireAccess({ action: 'admin.knowledge.manage', resource: 'none' })
  async deleteAsset(
    @Param('articleId') articleId: string,
    @Param('assetId') assetId: string,
    @Req() req: any,
  ) {
    await this.svc.deleteAsset(articleId, assetId, req.user.userId);
    return { id: assetId };
  }
}
