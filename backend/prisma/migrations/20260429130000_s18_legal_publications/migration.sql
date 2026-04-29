-- S18.3 Legal PDF publications
-- Отдельная сущность от LegalDocument: LegalDocument остаётся для markdown-acceptance,
-- LegalPublication — опциональные PDF-копии для публичного inline-просмотра в браузере.

-- CreateEnum
CREATE TYPE "LegalPublicationKind" AS ENUM ('privacy_policy', 'tos', 'data_processing_consent', 'other');

-- CreateTable
CREATE TABLE "LegalPublication" (
    "id" TEXT NOT NULL,
    "kind" "LegalPublicationKind" NOT NULL,
    "slug" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "fileKey" TEXT NOT NULL,
    "mimeType" TEXT NOT NULL,
    "sizeBytes" INTEGER NOT NULL,
    "etag" TEXT NOT NULL,
    "version" INTEGER NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT false,
    "publishedAt" TIMESTAMP(3),
    "publishedById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "LegalPublication_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "LegalPublication_slug_key" ON "LegalPublication"("slug");
CREATE INDEX "LegalPublication_kind_isActive_idx" ON "LegalPublication"("kind", "isActive");
CREATE INDEX "LegalPublication_kind_version_idx" ON "LegalPublication"("kind", "version");
