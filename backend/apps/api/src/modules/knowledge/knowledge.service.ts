import { createHash } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import {
  KnowledgeArticle,
  KnowledgeAsset,
  KnowledgeCategory,
  KnowledgeCategoryScope,
  Prisma,
} from '@prisma/client';
import { Clock, ErrorCodes, InvalidInputError, NotFoundError, PrismaService } from '@app/common';
import { FilesService } from '@app/files';
import { AdminAuditService } from '../admin-audit/admin-audit.service';
import {
  ConfirmKnowledgeAssetDto,
  CreateKnowledgeArticleDto,
  CreateKnowledgeCategoryDto,
  SetAssetThumbnailDto,
  UpdateKnowledgeArticleDto,
  UpdateKnowledgeCategoryDto,
} from './dto';

@Injectable()
export class KnowledgeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
    private readonly audit: AdminAuditService,
    private readonly files: FilesService,
  ) {}

  // ---------- Public read ----------

  async listCategories(filters: {
    scope?: KnowledgeCategoryScope;
    moduleSlug?: string;
  }): Promise<Array<KnowledgeCategory & { articleCount: number }>> {
    const where: Prisma.KnowledgeCategoryWhereInput = { isPublished: true };
    if (filters.scope) where.scope = filters.scope;
    if (filters.moduleSlug) where.moduleSlug = filters.moduleSlug;

    const cats = await this.prisma.knowledgeCategory.findMany({
      where,
      orderBy: [{ orderIndex: 'asc' }, { createdAt: 'asc' }],
      include: {
        _count: { select: { articles: { where: { isPublished: true } } } },
      },
    });
    return cats.map((c) => ({ ...c, articleCount: c._count.articles }));
  }

  async getCategoryWithArticles(id: string) {
    const cat = await this.prisma.knowledgeCategory.findUnique({
      where: { id },
      include: {
        articles: {
          where: { isPublished: true },
          orderBy: [{ orderIndex: 'asc' }, { createdAt: 'asc' }],
          select: {
            id: true,
            title: true,
            orderIndex: true,
            etag: true,
            version: true,
            updatedAt: true,
          },
        },
      },
    });
    if (!cat) {
      throw new NotFoundError(ErrorCodes.KNOWLEDGE_CATEGORY_NOT_FOUND, `category not found: ${id}`);
    }
    return cat;
  }

  async getArticle(id: string) {
    const article = await this.prisma.knowledgeArticle.findUnique({
      where: { id },
      include: {
        assets: {
          orderBy: [{ orderIndex: 'asc' }, { createdAt: 'asc' }],
        },
        category: { select: { id: true, title: true } },
      },
    });
    if (!article || !article.isPublished) {
      throw new NotFoundError(ErrorCodes.KNOWLEDGE_ARTICLE_NOT_FOUND, `article not found: ${id}`);
    }
    return article;
  }

  /** Presigned download URL для media-asset (видео/файл streaming). */
  async getAssetDownloadUrl(
    articleId: string,
    assetId: string,
  ): Promise<{ url: string; expiresAt: Date }> {
    const asset = await this.prisma.knowledgeAsset.findFirst({
      where: { id: assetId, articleId },
    });
    if (!asset) {
      throw new NotFoundError(ErrorCodes.KNOWLEDGE_ASSET_NOT_FOUND, `asset not found: ${assetId}`);
    }
    return this.files.createPresignedDownload(asset.fileKey);
  }

  // ---------- Admin: categories ----------

  async listAllCategories() {
    return this.prisma.knowledgeCategory.findMany({
      orderBy: [{ orderIndex: 'asc' }, { createdAt: 'asc' }],
      include: {
        _count: { select: { articles: true } },
      },
    });
  }

  async createCategory(
    actorId: string,
    dto: CreateKnowledgeCategoryDto,
  ): Promise<KnowledgeCategory> {
    if (dto.scope === 'project_module' && !dto.moduleSlug) {
      throw new InvalidInputError(
        ErrorCodes.KNOWLEDGE_INVALID_MODULE_SLUG,
        'moduleSlug is required when scope=project_module',
      );
    }
    const cat = await this.prisma.knowledgeCategory.create({
      data: {
        title: dto.title,
        description: dto.description,
        iconKey: dto.iconKey,
        scope: dto.scope,
        moduleSlug: dto.scope === 'project_module' ? dto.moduleSlug : null,
        orderIndex: dto.orderIndex ?? 0,
      },
    });
    await this.audit.log({
      actorId,
      action: 'knowledge.category_created',
      targetType: 'KnowledgeCategory',
      targetId: cat.id,
      metadata: { scope: cat.scope, moduleSlug: cat.moduleSlug },
    });
    return cat;
  }

  async updateCategory(
    id: string,
    actorId: string,
    dto: UpdateKnowledgeCategoryDto,
  ): Promise<KnowledgeCategory> {
    const existing = await this.prisma.knowledgeCategory.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError(ErrorCodes.KNOWLEDGE_CATEGORY_NOT_FOUND, 'category not found');
    }
    const nextScope = dto.scope ?? existing.scope;
    if (nextScope === 'project_module') {
      const nextSlug = dto.moduleSlug !== undefined ? dto.moduleSlug : existing.moduleSlug;
      if (!nextSlug) {
        throw new InvalidInputError(
          ErrorCodes.KNOWLEDGE_INVALID_MODULE_SLUG,
          'moduleSlug is required when scope=project_module',
        );
      }
    }
    const updated = await this.prisma.knowledgeCategory.update({
      where: { id },
      data: {
        title: dto.title,
        description: dto.description,
        iconKey: dto.iconKey,
        scope: dto.scope,
        moduleSlug: nextScope === 'project_module' ? (dto.moduleSlug ?? existing.moduleSlug) : null,
        orderIndex: dto.orderIndex,
        isPublished: dto.isPublished,
      },
    });
    await this.audit.log({
      actorId,
      action: 'knowledge.category_updated',
      targetType: 'KnowledgeCategory',
      targetId: id,
    });
    return updated;
  }

  async deleteCategory(id: string, actorId: string): Promise<void> {
    const existing = await this.prisma.knowledgeCategory.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError(ErrorCodes.KNOWLEDGE_CATEGORY_NOT_FOUND, 'category not found');
    }
    await this.prisma.knowledgeCategory.delete({ where: { id } });
    await this.audit.log({
      actorId,
      action: 'knowledge.category_deleted',
      targetType: 'KnowledgeCategory',
      targetId: id,
    });
  }

  // ---------- Admin: articles ----------

  async createArticle(actorId: string, dto: CreateKnowledgeArticleDto): Promise<KnowledgeArticle> {
    const cat = await this.prisma.knowledgeCategory.findUnique({
      where: { id: dto.categoryId },
    });
    if (!cat) {
      throw new NotFoundError(ErrorCodes.KNOWLEDGE_CATEGORY_NOT_FOUND, 'category not found');
    }
    const etag = computeEtag(dto.title, dto.body, []);
    const article = await this.prisma.knowledgeArticle.create({
      data: {
        categoryId: dto.categoryId,
        title: dto.title,
        body: dto.body,
        etag,
        orderIndex: dto.orderIndex ?? 0,
        isPublished: dto.isPublished ?? true,
        publishedAt: (dto.isPublished ?? true) ? this.clock.now() : null,
      },
    });
    await this.audit.log({
      actorId,
      action: 'knowledge.article_created',
      targetType: 'KnowledgeArticle',
      targetId: article.id,
      metadata: { categoryId: article.categoryId },
    });
    return article;
  }

  async updateArticle(
    id: string,
    actorId: string,
    dto: UpdateKnowledgeArticleDto,
  ): Promise<KnowledgeArticle> {
    const existing = await this.prisma.knowledgeArticle.findUnique({
      where: { id },
      include: { assets: true },
    });
    if (!existing) {
      throw new NotFoundError(ErrorCodes.KNOWLEDGE_ARTICLE_NOT_FOUND, 'article not found');
    }
    const nextTitle = dto.title ?? existing.title;
    const nextBody = dto.body ?? existing.body;
    const contentChanged = dto.title !== undefined || dto.body !== undefined;
    const etag = contentChanged
      ? computeEtag(
          nextTitle,
          nextBody,
          existing.assets.map((a) => a.fileKey),
        )
      : existing.etag;
    const updated = await this.prisma.knowledgeArticle.update({
      where: { id },
      data: {
        title: dto.title,
        body: dto.body,
        categoryId: dto.categoryId,
        orderIndex: dto.orderIndex,
        isPublished: dto.isPublished,
        etag,
        version: contentChanged ? existing.version + 1 : existing.version,
        publishedAt:
          dto.isPublished === true && !existing.publishedAt
            ? this.clock.now()
            : dto.isPublished === false
              ? null
              : existing.publishedAt,
      },
    });
    await this.audit.log({
      actorId,
      action: 'knowledge.article_updated',
      targetType: 'KnowledgeArticle',
      targetId: id,
      metadata: { contentChanged },
    });
    return updated;
  }

  async deleteArticle(id: string, actorId: string): Promise<void> {
    const existing = await this.prisma.knowledgeArticle.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError(ErrorCodes.KNOWLEDGE_ARTICLE_NOT_FOUND, 'article not found');
    }
    await this.prisma.knowledgeArticle.delete({ where: { id } });
    await this.audit.log({
      actorId,
      action: 'knowledge.article_deleted',
      targetType: 'KnowledgeArticle',
      targetId: id,
    });
  }

  // ---------- Admin: assets (после presigned upload) ----------

  async confirmAsset(
    articleId: string,
    actorId: string,
    dto: ConfirmKnowledgeAssetDto,
  ): Promise<KnowledgeAsset> {
    const article = await this.prisma.knowledgeArticle.findUnique({
      where: { id: articleId },
      include: { assets: true },
    });
    if (!article) {
      throw new NotFoundError(ErrorCodes.KNOWLEDGE_ARTICLE_NOT_FOUND, 'article not found');
    }
    // Подтверждаем что файл лежит в MinIO.
    let stat: { size: number };
    try {
      stat = await this.files.statObject(dto.fileKey);
    } catch {
      throw new NotFoundError(
        ErrorCodes.KNOWLEDGE_ASSET_FILE_MISSING,
        `file not in storage: ${dto.fileKey}`,
      );
    }
    if (stat.size !== dto.sizeBytes) {
      throw new InvalidInputError(
        'knowledge.asset_size_mismatch',
        `size mismatch: stored=${stat.size}, claimed=${dto.sizeBytes}`,
      );
    }
    const created = await this.prisma.knowledgeAsset.create({
      data: {
        articleId,
        kind: dto.kind,
        fileKey: dto.fileKey,
        mimeType: dto.mimeType,
        sizeBytes: dto.sizeBytes,
        durationSec: dto.durationSec,
        width: dto.width,
        height: dto.height,
        caption: dto.caption,
        orderIndex: dto.orderIndex ?? 0,
      },
    });
    // ETag статьи зависит от списка assets — пересчитываем.
    await this.recomputeArticleEtag(articleId);
    await this.audit.log({
      actorId,
      action: 'knowledge.asset_confirmed',
      targetType: 'KnowledgeAsset',
      targetId: created.id,
      metadata: { articleId, kind: dto.kind, sizeBytes: dto.sizeBytes },
    });
    return created;
  }

  async setAssetThumbnail(
    articleId: string,
    assetId: string,
    actorId: string,
    dto: SetAssetThumbnailDto,
  ): Promise<KnowledgeAsset> {
    const asset = await this.prisma.knowledgeAsset.findFirst({
      where: { id: assetId, articleId },
    });
    if (!asset) {
      throw new NotFoundError(ErrorCodes.KNOWLEDGE_ASSET_NOT_FOUND, 'asset not found');
    }
    try {
      await this.files.statObject(dto.fileKey);
    } catch {
      throw new NotFoundError(
        ErrorCodes.KNOWLEDGE_ASSET_FILE_MISSING,
        `thumb file not in storage: ${dto.fileKey}`,
      );
    }
    const updated = await this.prisma.knowledgeAsset.update({
      where: { id: assetId },
      data: { thumbKey: dto.fileKey },
    });
    await this.audit.log({
      actorId,
      action: 'knowledge.asset_thumbnail_set',
      targetType: 'KnowledgeAsset',
      targetId: assetId,
    });
    return updated;
  }

  async deleteAsset(articleId: string, assetId: string, actorId: string): Promise<void> {
    const asset = await this.prisma.knowledgeAsset.findFirst({
      where: { id: assetId, articleId },
    });
    if (!asset) {
      throw new NotFoundError(ErrorCodes.KNOWLEDGE_ASSET_NOT_FOUND, 'asset not found');
    }
    await this.prisma.knowledgeAsset.delete({ where: { id: assetId } });
    await this.recomputeArticleEtag(articleId);
    await this.audit.log({
      actorId,
      action: 'knowledge.asset_deleted',
      targetType: 'KnowledgeAsset',
      targetId: assetId,
    });
  }

  // ---------- Helpers ----------

  private async recomputeArticleEtag(articleId: string): Promise<void> {
    const article = await this.prisma.knowledgeArticle.findUnique({
      where: { id: articleId },
      include: { assets: { orderBy: { orderIndex: 'asc' } } },
    });
    if (!article) return;
    const etag = computeEtag(
      article.title,
      article.body,
      article.assets.map((a) => a.fileKey),
    );
    if (etag !== article.etag) {
      await this.prisma.knowledgeArticle.update({
        where: { id: articleId },
        data: { etag, version: article.version + 1 },
      });
    }
  }
}

function computeEtag(title: string, body: string, assetKeys: string[]): string {
  const sorted = [...assetKeys].sort();
  return createHash('sha256')
    .update(`${title}\n${body}\n${sorted.join(',')}`)
    .digest('hex');
}
