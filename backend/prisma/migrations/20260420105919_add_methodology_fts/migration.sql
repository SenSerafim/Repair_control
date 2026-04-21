-- Methodology FTS (ТЗ §8 спринт 3 день 6): русская морфология + trigram fallback.

CREATE EXTENSION IF NOT EXISTS pg_trgm;

ALTER TABLE "MethodologyArticle"
  ADD COLUMN "searchVector" tsvector
  GENERATED ALWAYS AS (
    to_tsvector('russian', coalesce("title", '') || ' ' || coalesce("body", ''))
  ) STORED;

CREATE INDEX "methodology_article_fts_idx"
  ON "MethodologyArticle" USING GIN ("searchVector");

CREATE INDEX "methodology_article_trgm_idx"
  ON "MethodologyArticle" USING GIN ("title" gin_trgm_ops);
