-- Methodology FTS (ТЗ §8 спринт 3 день 6): русская морфология + trigram fallback.
-- Search вычисляется в $queryRaw через to_tsvector('russian', title || ' ' || body) —
-- без сохранённой колонки. Trigram-индекс ускоряет fallback по опечаткам в title.

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS "methodology_article_trgm_idx"
  ON "MethodologyArticle" USING GIN ("title" gin_trgm_ops);
