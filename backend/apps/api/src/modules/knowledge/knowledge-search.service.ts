import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@app/common';

export interface KnowledgeSearchHit {
  id: string;
  categoryId: string;
  title: string;
  snippet: string;
  rank: number;
}

@Injectable()
export class KnowledgeSearchService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * FTS-поиск по статьям БЗ. Использует GENERATED tsvector + GIN-индекс
   * (`KnowledgeArticle_searchVector_idx`). Fallback на trigram match по title
   * для опечаток. Возвращает до `limit` результатов в порядке убывания rank.
   */
  async search(opts: {
    q: string;
    limit?: number;
    scope?: string;
    moduleSlug?: string;
  }): Promise<KnowledgeSearchHit[]> {
    const q = opts.q.trim();
    const limit = Math.min(Math.max(opts.limit ?? 20, 1), 50);
    if (q.length < 2) return [];

    // plainto_tsquery — безопасный парсер пользовательского ввода.
    // ts_rank — релевантность, ts_headline — сниппет с <mark>...</mark> подсветкой.
    const scopeFilter = opts.scope ? Prisma.sql`AND c."scope"::text = ${opts.scope}` : Prisma.empty;
    const moduleFilter = opts.moduleSlug
      ? Prisma.sql`AND c."moduleSlug" = ${opts.moduleSlug}`
      : Prisma.empty;

    const rows = await this.prisma.$queryRaw<
      Array<{
        id: string;
        categoryId: string;
        title: string;
        snippet: string;
        rank: number;
      }>
    >(Prisma.sql`
      WITH q AS (SELECT plainto_tsquery('russian', ${q}) AS query)
      SELECT
        a."id",
        a."categoryId",
        a."title",
        ts_headline(
          'russian',
          a."body",
          q.query,
          'StartSel=<mark>, StopSel=</mark>, MaxFragments=2, MinWords=5, MaxWords=18'
        ) AS snippet,
        ts_rank(a."searchVector", q.query) AS rank
      FROM "KnowledgeArticle" a
      JOIN "KnowledgeCategory" c ON c."id" = a."categoryId"
      CROSS JOIN q
      WHERE a."isPublished" = true
        AND c."isPublished" = true
        AND (a."searchVector" @@ q.query OR a."title" % ${q})
        ${scopeFilter}
        ${moduleFilter}
      ORDER BY rank DESC, a."updatedAt" DESC
      LIMIT ${limit}
    `);

    return rows.map((r) => ({
      id: r.id,
      categoryId: r.categoryId,
      title: r.title,
      snippet: r.snippet,
      rank: typeof r.rank === 'number' ? r.rank : Number(r.rank),
    }));
  }
}
