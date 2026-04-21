-- CreateEnum
CREATE TYPE "SelfPurchaseStatus" AS ENUM ('pending', 'approved', 'rejected');

-- CreateEnum
CREATE TYPE "SelfPurchaseBy" AS ENUM ('foreman', 'master');

-- CreateEnum
CREATE TYPE "ToolIssuanceStatus" AS ENUM ('issued', 'confirmed', 'return_requested', 'returned');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "FeedEventKind" ADD VALUE 'selfpurchase_created';
ALTER TYPE "FeedEventKind" ADD VALUE 'selfpurchase_approved';
ALTER TYPE "FeedEventKind" ADD VALUE 'selfpurchase_rejected';
ALTER TYPE "FeedEventKind" ADD VALUE 'tool_issued';
ALTER TYPE "FeedEventKind" ADD VALUE 'tool_issuance_confirmed';
ALTER TYPE "FeedEventKind" ADD VALUE 'tool_return_requested';
ALTER TYPE "FeedEventKind" ADD VALUE 'tool_returned';
ALTER TYPE "FeedEventKind" ADD VALUE 'foreman_removed';
ALTER TYPE "FeedEventKind" ADD VALUE 'foreman_replaced';
ALTER TYPE "FeedEventKind" ADD VALUE 'stage_budget_edit_after_start';

-- AlterTable
ALTER TABLE "Approval" ADD COLUMN     "requiresReassign" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable
CREATE TABLE "SelfPurchase" (
    "id" TEXT NOT NULL,
    "projectId" TEXT NOT NULL,
    "stageId" TEXT,
    "byUserId" TEXT NOT NULL,
    "byRole" "SelfPurchaseBy" NOT NULL,
    "addresseeId" TEXT NOT NULL,
    "amount" BIGINT NOT NULL,
    "comment" TEXT,
    "photoKeys" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "status" "SelfPurchaseStatus" NOT NULL DEFAULT 'pending',
    "decidedAt" TIMESTAMP(3),
    "decidedById" TEXT,
    "decisionComment" TEXT,
    "idempotencyKey" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SelfPurchase_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ToolItem" (
    "id" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "totalQty" INTEGER NOT NULL,
    "issuedQty" INTEGER NOT NULL DEFAULT 0,
    "unit" TEXT DEFAULT 'шт',
    "photoKey" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ToolItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ToolIssuance" (
    "id" TEXT NOT NULL,
    "toolItemId" TEXT NOT NULL,
    "projectId" TEXT,
    "stageId" TEXT,
    "toUserId" TEXT NOT NULL,
    "issuedById" TEXT NOT NULL,
    "qty" INTEGER NOT NULL,
    "returnedQty" INTEGER,
    "status" "ToolIssuanceStatus" NOT NULL DEFAULT 'issued',
    "issuedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "confirmedAt" TIMESTAMP(3),
    "returnedAt" TIMESTAMP(3),
    "returnConfirmedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ToolIssuance_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "SelfPurchase_idempotencyKey_key" ON "SelfPurchase"("idempotencyKey");

-- CreateIndex
CREATE INDEX "SelfPurchase_projectId_status_idx" ON "SelfPurchase"("projectId", "status");

-- CreateIndex
CREATE INDEX "SelfPurchase_addresseeId_status_idx" ON "SelfPurchase"("addresseeId", "status");

-- CreateIndex
CREATE INDEX "ToolItem_ownerId_idx" ON "ToolItem"("ownerId");

-- CreateIndex
CREATE INDEX "ToolIssuance_toolItemId_status_idx" ON "ToolIssuance"("toolItemId", "status");

-- CreateIndex
CREATE INDEX "ToolIssuance_toUserId_status_idx" ON "ToolIssuance"("toUserId", "status");

-- CreateIndex
CREATE INDEX "ToolIssuance_projectId_idx" ON "ToolIssuance"("projectId");

-- AddForeignKey
ALTER TABLE "SelfPurchase" ADD CONSTRAINT "SelfPurchase_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SelfPurchase" ADD CONSTRAINT "SelfPurchase_stageId_fkey" FOREIGN KEY ("stageId") REFERENCES "Stage"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ToolIssuance" ADD CONSTRAINT "ToolIssuance_toolItemId_fkey" FOREIGN KEY ("toolItemId") REFERENCES "ToolItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;
