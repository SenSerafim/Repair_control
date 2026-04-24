/*
  Warnings:

  - You are about to drop the column `searchVector` on the `MethodologyArticle` table. All the data in the column will be lost.

*/
-- CreateEnum
CREATE TYPE "PaymentKind" AS ENUM ('advance', 'distribution', 'correction');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('pending', 'confirmed', 'disputed', 'resolved', 'cancelled');

-- CreateEnum
CREATE TYPE "MaterialRequestStatus" AS ENUM ('draft', 'open', 'partially_bought', 'bought', 'delivered', 'disputed', 'resolved', 'cancelled');

-- CreateEnum
CREATE TYPE "MaterialRecipient" AS ENUM ('foreman', 'customer');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "FeedEventKind" ADD VALUE 'payment_created';
ALTER TYPE "FeedEventKind" ADD VALUE 'payment_confirmed';
ALTER TYPE "FeedEventKind" ADD VALUE 'payment_cancelled';
ALTER TYPE "FeedEventKind" ADD VALUE 'payment_disputed';
ALTER TYPE "FeedEventKind" ADD VALUE 'payment_resolved';
ALTER TYPE "FeedEventKind" ADD VALUE 'payment_distributed';
ALTER TYPE "FeedEventKind" ADD VALUE 'material_request_created';
ALTER TYPE "FeedEventKind" ADD VALUE 'material_request_sent';
ALTER TYPE "FeedEventKind" ADD VALUE 'material_item_bought';
ALTER TYPE "FeedEventKind" ADD VALUE 'material_request_finalized';
ALTER TYPE "FeedEventKind" ADD VALUE 'material_delivered';
ALTER TYPE "FeedEventKind" ADD VALUE 'material_disputed';
ALTER TYPE "FeedEventKind" ADD VALUE 'material_resolved';

-- DropIndex: searchVector GENERATED-колонка и fts_idx не применялись на чистой БД
-- (Prisma migrate deploy не поддерживает ADD COLUMN GENERATED ALWAYS AS STORED).
-- FTS теперь вычисляется в $queryRaw налету (см. MethodologyService.search).
-- trgm_idx нужен для fallback по опечаткам — НЕ дропаем.
DROP INDEX IF EXISTS "methodology_article_fts_idx";

-- AlterTable: searchVector могло не создаться — IF EXISTS страхует.
ALTER TABLE "MethodologyArticle" DROP COLUMN IF EXISTS "searchVector";

-- CreateTable
CREATE TABLE "Payment" (
    "id" TEXT NOT NULL,
    "projectId" TEXT NOT NULL,
    "stageId" TEXT,
    "parentPaymentId" TEXT,
    "kind" "PaymentKind" NOT NULL,
    "fromUserId" TEXT NOT NULL,
    "toUserId" TEXT NOT NULL,
    "amount" BIGINT NOT NULL,
    "resolvedAmount" BIGINT,
    "comment" TEXT,
    "photoKey" TEXT,
    "status" "PaymentStatus" NOT NULL DEFAULT 'pending',
    "idempotencyKey" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "confirmedAt" TIMESTAMP(3),
    "disputedAt" TIMESTAMP(3),
    "resolvedAt" TIMESTAMP(3),
    "cancelledAt" TIMESTAMP(3),
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Payment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PaymentDispute" (
    "id" TEXT NOT NULL,
    "paymentId" TEXT NOT NULL,
    "openedById" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'open',
    "resolution" TEXT,
    "resolvedAt" TIMESTAMP(3),
    "resolvedBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PaymentDispute_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MaterialRequest" (
    "id" TEXT NOT NULL,
    "projectId" TEXT NOT NULL,
    "stageId" TEXT,
    "createdById" TEXT NOT NULL,
    "recipient" "MaterialRecipient" NOT NULL,
    "title" TEXT NOT NULL,
    "comment" TEXT,
    "status" "MaterialRequestStatus" NOT NULL DEFAULT 'draft',
    "finalizedAt" TIMESTAMP(3),
    "deliveredAt" TIMESTAMP(3),
    "deliveredById" TEXT,
    "idempotencyKey" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MaterialRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MaterialItem" (
    "id" TEXT NOT NULL,
    "requestId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "qty" DECIMAL(12,3) NOT NULL,
    "unit" TEXT,
    "note" TEXT,
    "pricePerUnit" BIGINT,
    "totalPrice" BIGINT,
    "isBought" BOOLEAN NOT NULL DEFAULT false,
    "boughtAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MaterialItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MaterialDispute" (
    "id" TEXT NOT NULL,
    "requestId" TEXT NOT NULL,
    "openedById" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'open',
    "resolution" TEXT,
    "resolvedAt" TIMESTAMP(3),
    "resolvedBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MaterialDispute_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "IdempotencyRecord" (
    "key" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "endpoint" TEXT NOT NULL,
    "requestHash" TEXT NOT NULL,
    "statusCode" INTEGER,
    "response" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "IdempotencyRecord_pkey" PRIMARY KEY ("key")
);

-- CreateIndex
CREATE UNIQUE INDEX "Payment_idempotencyKey_key" ON "Payment"("idempotencyKey");

-- CreateIndex
CREATE INDEX "Payment_projectId_status_idx" ON "Payment"("projectId", "status");

-- CreateIndex
CREATE INDEX "Payment_fromUserId_idx" ON "Payment"("fromUserId");

-- CreateIndex
CREATE INDEX "Payment_toUserId_idx" ON "Payment"("toUserId");

-- CreateIndex
CREATE INDEX "Payment_parentPaymentId_idx" ON "Payment"("parentPaymentId");

-- CreateIndex
CREATE INDEX "Payment_stageId_idx" ON "Payment"("stageId");

-- CreateIndex
CREATE INDEX "PaymentDispute_paymentId_status_idx" ON "PaymentDispute"("paymentId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "MaterialRequest_idempotencyKey_key" ON "MaterialRequest"("idempotencyKey");

-- CreateIndex
CREATE INDEX "MaterialRequest_projectId_status_idx" ON "MaterialRequest"("projectId", "status");

-- CreateIndex
CREATE INDEX "MaterialRequest_stageId_idx" ON "MaterialRequest"("stageId");

-- CreateIndex
CREATE INDEX "MaterialItem_requestId_idx" ON "MaterialItem"("requestId");

-- CreateIndex
CREATE INDEX "MaterialDispute_requestId_status_idx" ON "MaterialDispute"("requestId", "status");

-- CreateIndex
CREATE INDEX "IdempotencyRecord_userId_endpoint_idx" ON "IdempotencyRecord"("userId", "endpoint");

-- CreateIndex
CREATE INDEX "IdempotencyRecord_expiresAt_idx" ON "IdempotencyRecord"("expiresAt");

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_stageId_fkey" FOREIGN KEY ("stageId") REFERENCES "Stage"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_parentPaymentId_fkey" FOREIGN KEY ("parentPaymentId") REFERENCES "Payment"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PaymentDispute" ADD CONSTRAINT "PaymentDispute_paymentId_fkey" FOREIGN KEY ("paymentId") REFERENCES "Payment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MaterialRequest" ADD CONSTRAINT "MaterialRequest_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MaterialRequest" ADD CONSTRAINT "MaterialRequest_stageId_fkey" FOREIGN KEY ("stageId") REFERENCES "Stage"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MaterialItem" ADD CONSTRAINT "MaterialItem_requestId_fkey" FOREIGN KEY ("requestId") REFERENCES "MaterialRequest"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MaterialDispute" ADD CONSTRAINT "MaterialDispute_requestId_fkey" FOREIGN KEY ("requestId") REFERENCES "MaterialRequest"("id") ON DELETE CASCADE ON UPDATE CASCADE;
