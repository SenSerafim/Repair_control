-- S18.4 Knowledge Base
-- Категории + статьи + ассеты (image/video/file). FTS через GENERATED tsvector
-- (раскрывает GIN-индекс — поиск по 1000+ статьям без полного сканирования).

-- CreateEnum
CREATE TYPE "KnowledgeCategoryScope" AS ENUM ('global', 'project_module');
CREATE TYPE "KnowledgeAssetKind" AS ENUM ('image', 'video', 'file');

-- CreateTable
CREATE TABLE "KnowledgeCategory" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "iconKey" TEXT,
    "scope" "KnowledgeCategoryScope" NOT NULL DEFAULT 'global',
    "moduleSlug" TEXT,
    "orderIndex" INTEGER NOT NULL DEFAULT 0,
    "isPublished" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "KnowledgeCategory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "KnowledgeArticle" (
    "id" TEXT NOT NULL,
    "categoryId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "etag" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "isPublished" BOOLEAN NOT NULL DEFAULT true,
    "orderIndex" INTEGER NOT NULL DEFAULT 0,
    "publishedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "KnowledgeArticle_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "KnowledgeAsset" (
    "id" TEXT NOT NULL,
    "articleId" TEXT NOT NULL,
    "kind" "KnowledgeAssetKind" NOT NULL,
    "fileKey" TEXT NOT NULL,
    "mimeType" TEXT NOT NULL,
    "sizeBytes" INTEGER NOT NULL,
    "durationSec" INTEGER,
    "width" INTEGER,
    "height" INTEGER,
    "thumbKey" TEXT,
    "caption" TEXT,
    "orderIndex" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "KnowledgeAsset_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "KnowledgeCategory_scope_orderIndex_idx" ON "KnowledgeCategory"("scope", "orderIndex");
CREATE INDEX "KnowledgeCategory_moduleSlug_idx" ON "KnowledgeCategory"("moduleSlug");
CREATE INDEX "KnowledgeArticle_categoryId_orderIndex_idx" ON "KnowledgeArticle"("categoryId", "orderIndex");
CREATE INDEX "KnowledgeAsset_articleId_orderIndex_idx" ON "KnowledgeAsset"("articleId", "orderIndex");

-- AddForeignKey
ALTER TABLE "KnowledgeArticle" ADD CONSTRAINT "KnowledgeArticle_categoryId_fkey"
  FOREIGN KEY ("categoryId") REFERENCES "KnowledgeCategory"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "KnowledgeAsset" ADD CONSTRAINT "KnowledgeAsset_articleId_fkey"
  FOREIGN KEY ("articleId") REFERENCES "KnowledgeArticle"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- FTS: GENERATED stored tsvector + GIN index. На 1000+ статьях это даёт
-- ON-the-fly индексированный поиск без полного сканирования таблицы.
-- Prisma не управляет колонкой searchVector — она вне типизированной модели,
-- запросы идут через $queryRaw с явным WHERE searchVector @@ to_tsquery(...).
ALTER TABLE "KnowledgeArticle"
  ADD COLUMN "searchVector" tsvector
  GENERATED ALWAYS AS (
    to_tsvector('russian', coalesce("title", '') || ' ' || coalesce("body", ''))
  ) STORED;

CREATE INDEX "KnowledgeArticle_searchVector_idx" ON "KnowledgeArticle" USING GIN ("searchVector");

-- Триграммный fallback для опечаток в title (pg_trgm extension уже включён в S3-методичке).
CREATE INDEX "KnowledgeArticle_title_trgm_idx" ON "KnowledgeArticle" USING GIN ("title" gin_trgm_ops);
