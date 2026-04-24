-- CreateEnum
CREATE TYPE "LegalKind" AS ENUM ('privacy', 'tos', 'data_processing_consent');

-- CreateEnum
CREATE TYPE "BroadcastStatus" AS ENUM ('draft', 'queued', 'sent', 'failed');


-- AlterTable
ALTER TABLE "User" ADD COLUMN     "banReason" TEXT,
ADD COLUMN     "bannedAt" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "LegalDocument" (
    "id" TEXT NOT NULL,
    "kind" "LegalKind" NOT NULL,
    "version" INTEGER NOT NULL,
    "title" TEXT NOT NULL,
    "bodyMd" TEXT NOT NULL,
    "publishedAt" TIMESTAMP(3),
    "publishedById" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "LegalDocument_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LegalAcceptance" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "documentId" TEXT NOT NULL,
    "acceptedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "LegalAcceptance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BroadcastCampaign" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "deepLink" TEXT,
    "filter" JSONB NOT NULL DEFAULT '{}',
    "createdById" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sentAt" TIMESTAMP(3),
    "targetCount" INTEGER NOT NULL DEFAULT 0,
    "queuedCount" INTEGER NOT NULL DEFAULT 0,
    "deliveredCount" INTEGER NOT NULL DEFAULT 0,
    "failedCount" INTEGER NOT NULL DEFAULT 0,
    "status" "BroadcastStatus" NOT NULL DEFAULT 'draft',

    CONSTRAINT "BroadcastCampaign_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AdminAuditLog" (
    "id" TEXT NOT NULL,
    "actorId" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "targetType" TEXT,
    "targetId" TEXT,
    "metadata" JSONB NOT NULL DEFAULT '{}',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AdminAuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "LegalDocument_kind_isActive_idx" ON "LegalDocument"("kind", "isActive");

-- CreateIndex
CREATE INDEX "LegalDocument_kind_publishedAt_idx" ON "LegalDocument"("kind", "publishedAt");

-- CreateIndex
CREATE UNIQUE INDEX "LegalDocument_kind_version_key" ON "LegalDocument"("kind", "version");

-- CreateIndex
CREATE INDEX "LegalAcceptance_userId_idx" ON "LegalAcceptance"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "LegalAcceptance_userId_documentId_key" ON "LegalAcceptance"("userId", "documentId");

-- CreateIndex
CREATE INDEX "BroadcastCampaign_createdById_createdAt_idx" ON "BroadcastCampaign"("createdById", "createdAt");

-- CreateIndex
CREATE INDEX "BroadcastCampaign_status_idx" ON "BroadcastCampaign"("status");

-- CreateIndex
CREATE INDEX "AdminAuditLog_actorId_createdAt_idx" ON "AdminAuditLog"("actorId", "createdAt");

-- CreateIndex
CREATE INDEX "AdminAuditLog_action_createdAt_idx" ON "AdminAuditLog"("action", "createdAt");

-- CreateIndex
CREATE INDEX "AdminAuditLog_targetType_targetId_idx" ON "AdminAuditLog"("targetType", "targetId");

-- AddForeignKey
ALTER TABLE "LegalAcceptance" ADD CONSTRAINT "LegalAcceptance_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LegalAcceptance" ADD CONSTRAINT "LegalAcceptance_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "LegalDocument"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- Re-guarded trgm index (ручной, Prisma о нём не знает)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS "methodology_article_trgm_idx"
  ON "MethodologyArticle" USING GIN ("title" gin_trgm_ops);
