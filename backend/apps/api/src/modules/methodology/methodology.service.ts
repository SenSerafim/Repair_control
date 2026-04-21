import * as crypto from 'crypto';
import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { ErrorCodes, InvalidInputError, NotFoundError, PrismaService } from '@app/common';
import { FeedService } from '../feed/feed.service';

export interface SearchHit {
  id: string;
  sectionId: string;
  title: string;
  snippet: string;
  rank: number;
}

@Injectable()
export class MethodologyService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly feed: FeedService,
  ) {}

  // ---- Sections ----

  async listSections() {
    return this.prisma.methodologySection.findMany({
      orderBy: { orderIndex: 'asc' },
      include: {
        articles: {
          orderBy: { orderIndex: 'asc' },
          select: { id: true, title: true, orderIndex: true, version: true, etag: true },
        },
      },
    });
  }

  async getSection(id: string) {
    const s = await this.prisma.methodologySection.findUnique({
      where: { id },
      include: { articles: { orderBy: { orderIndex: 'asc' } } },
    });
    if (!s) throw new NotFoundError(ErrorCodes.METHODOLOGY_SECTION_NOT_FOUND, 'section not found');
    return s;
  }

  async createSection(input: { title: string; orderIndex: number; actorUserId: string }) {
    const s = await this.prisma.$transaction(async (tx) => {
      const created = await tx.methodologySection.create({
        data: { title: input.title.trim(), orderIndex: input.orderIndex },
      });
      await this.feed.emit({
        tx,
        kind: 'methodology_section_created',
        projectId: null,
        actorId: input.actorUserId,
        payload: { sectionId: created.id, title: created.title },
      });
      return created;
    });
    return s;
  }

  async updateSection(
    id: string,
    input: { title?: string; orderIndex?: number; actorUserId: string },
  ) {
    const existing = await this.prisma.methodologySection.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError(ErrorCodes.METHODOLOGY_SECTION_NOT_FOUND, 'section not found');
    }
    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.methodologySection.update({
        where: { id },
        data: { title: input.title?.trim(), orderIndex: input.orderIndex },
      });
      await this.feed.emit({
        tx,
        kind: 'methodology_section_updated',
        projectId: null,
        actorId: input.actorUserId,
        payload: { sectionId: id },
      });
      return u;
    });
    return updated;
  }

  async deleteSection(id: string, actorUserId: string) {
    const existing = await this.prisma.methodologySection.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError(ErrorCodes.METHODOLOGY_SECTION_NOT_FOUND, 'section not found');
    }
    await this.prisma.$transaction(async (tx) => {
      await tx.methodologySection.delete({ where: { id } });
      await this.feed.emit({
        tx,
        kind: 'methodology_section_deleted',
        projectId: null,
        actorId: actorUserId,
        payload: { sectionId: id },
      });
    });
  }

  // ---- Articles ----

  async getArticle(id: string) {
    const a = await this.prisma.methodologyArticle.findUnique({
      where: { id },
      include: { referencePhotos: { orderBy: { orderIndex: 'asc' } } },
    });
    if (!a) throw new NotFoundError(ErrorCodes.METHODOLOGY_ARTICLE_NOT_FOUND, 'article not found');
    return a;
  }

  async createArticle(input: {
    sectionId: string;
    title: string;
    body: string;
    orderIndex: number;
    actorUserId: string;
  }) {
    const section = await this.prisma.methodologySection.findUnique({
      where: { id: input.sectionId },
    });
    if (!section) {
      throw new NotFoundError(ErrorCodes.METHODOLOGY_SECTION_NOT_FOUND, 'section not found');
    }
    const etag = this.computeEtag(input.title, input.body, []);
    const created = await this.prisma.$transaction(async (tx) => {
      const a = await tx.methodologyArticle.create({
        data: {
          sectionId: input.sectionId,
          title: input.title.trim(),
          body: input.body,
          orderIndex: input.orderIndex,
          version: 1,
          etag,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'methodology_article_created',
        projectId: null,
        actorId: input.actorUserId,
        payload: { articleId: a.id, sectionId: input.sectionId, title: a.title },
      });
      return a;
    });
    return created;
  }

  async updateArticle(
    id: string,
    input: { title?: string; body?: string; orderIndex?: number; actorUserId: string },
  ) {
    const existing = await this.prisma.methodologyArticle.findUnique({
      where: { id },
      include: { referencePhotos: true },
    });
    if (!existing) {
      throw new NotFoundError(ErrorCodes.METHODOLOGY_ARTICLE_NOT_FOUND, 'article not found');
    }
    const nextTitle = input.title !== undefined ? input.title.trim() : existing.title;
    const nextBody = input.body !== undefined ? input.body : existing.body;
    const contentChanged = input.title !== undefined || input.body !== undefined;
    const nextVersion = contentChanged ? existing.version + 1 : existing.version;
    const refKeys = existing.referencePhotos.map((p) => p.fileKey);
    const nextEtag = contentChanged
      ? this.computeEtag(nextTitle, nextBody, refKeys)
      : existing.etag;

    const updated = await this.prisma.$transaction(async (tx) => {
      const u = await tx.methodologyArticle.update({
        where: { id },
        data: {
          title: input.title !== undefined ? nextTitle : undefined,
          body: input.body !== undefined ? nextBody : undefined,
          orderIndex: input.orderIndex,
          version: nextVersion,
          etag: nextEtag,
        },
      });
      await this.feed.emit({
        tx,
        kind: 'methodology_article_updated',
        projectId: null,
        actorId: input.actorUserId,
        payload: { articleId: id, version: nextVersion },
      });
      return u;
    });
    return updated;
  }

  async deleteArticle(id: string, actorUserId: string) {
    const existing = await this.prisma.methodologyArticle.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError(ErrorCodes.METHODOLOGY_ARTICLE_NOT_FOUND, 'article not found');
    }
    await this.prisma.$transaction(async (tx) => {
      await tx.methodologyArticle.delete({ where: { id } });
      await this.feed.emit({
        tx,
        kind: 'methodology_article_deleted',
        projectId: null,
        actorId: actorUserId,
        payload: { articleId: id },
      });
    });
  }

  // ---- Search ----

  async search(query: string, limit = 20): Promise<SearchHit[]> {
    if (!query || query.trim().length === 0) {
      throw new InvalidInputError(
        ErrorCodes.METHODOLOGY_SEARCH_QUERY_REQUIRED,
        'search query is required',
      );
    }
    const q = query.trim();
    // FTS вычисляется налету: to_tsvector('russian', title || ' ' || body).
    // Trigram-fallback (%) ловит опечатки в title (pg_trgm установлен в миграции).
    const rows = await this.prisma.$queryRaw<
      Array<{ id: string; sectionId: string; title: string; snippet: string; rank: number }>
    >(Prisma.sql`
      SELECT
        a."id",
        a."sectionId",
        a."title",
        ts_headline(
          'russian',
          a."body",
          plainto_tsquery('russian', ${q}),
          'StartSel=«,StopSel=»,MaxWords=20,MinWords=5,ShortWord=2'
        ) AS snippet,
        ts_rank(
          to_tsvector('russian', coalesce(a."title", '') || ' ' || coalesce(a."body", '')),
          plainto_tsquery('russian', ${q})
        ) AS rank
      FROM "MethodologyArticle" a
      WHERE to_tsvector('russian', coalesce(a."title", '') || ' ' || coalesce(a."body", ''))
              @@ plainto_tsquery('russian', ${q})
         OR a."title" % ${q}
      ORDER BY rank DESC, a."updatedAt" DESC
      LIMIT ${limit}
    `);
    return rows.map((r) => ({
      id: r.id,
      sectionId: r.sectionId,
      title: r.title,
      snippet: r.snippet,
      rank: Number(r.rank),
    }));
  }

  // ---- ETag ----

  computeEtag(title: string, body: string, refKeys: string[]): string {
    const canonical = `${title}\n${body}\n${refKeys.join(',')}`;
    return crypto.createHash('sha256').update(canonical).digest('hex');
  }
}
