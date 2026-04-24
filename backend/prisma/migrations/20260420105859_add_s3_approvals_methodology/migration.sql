-- CreateEnum
CREATE TYPE "ApprovalScope" AS ENUM ('plan', 'step', 'extra_work', 'deadline_change', 'stage_accept');

-- CreateEnum
CREATE TYPE "ApprovalStatus" AS ENUM ('pending', 'approved', 'rejected', 'cancelled');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "FeedEventKind" ADD VALUE 'approval_requested';
ALTER TYPE "FeedEventKind" ADD VALUE 'approval_approved';
ALTER TYPE "FeedEventKind" ADD VALUE 'approval_rejected';
ALTER TYPE "FeedEventKind" ADD VALUE 'approval_cancelled';
ALTER TYPE "FeedEventKind" ADD VALUE 'approval_resubmitted';
ALTER TYPE "FeedEventKind" ADD VALUE 'plan_approved';
ALTER TYPE "FeedEventKind" ADD VALUE 'deadline_changed';
ALTER TYPE "FeedEventKind" ADD VALUE 'stage_accepted';
ALTER TYPE "FeedEventKind" ADD VALUE 'stage_rejected_by_customer';
ALTER TYPE "FeedEventKind" ADD VALUE 'budget_updated';
ALTER TYPE "FeedEventKind" ADD VALUE 'methodology_section_created';
ALTER TYPE "FeedEventKind" ADD VALUE 'methodology_section_updated';
ALTER TYPE "FeedEventKind" ADD VALUE 'methodology_section_deleted';
ALTER TYPE "FeedEventKind" ADD VALUE 'methodology_article_created';
ALTER TYPE "FeedEventKind" ADD VALUE 'methodology_article_updated';
ALTER TYPE "FeedEventKind" ADD VALUE 'methodology_article_deleted';

-- AlterTable
ALTER TABLE "Project" ADD COLUMN     "planApproved" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "requiresPlanApproval" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "Stage" ADD COLUMN     "planApproved" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable
CREATE TABLE "Approval" (
    "id" TEXT NOT NULL,
    "scope" "ApprovalScope" NOT NULL,
    "projectId" TEXT NOT NULL,
    "stageId" TEXT,
    "stepId" TEXT,
    "payload" JSONB NOT NULL DEFAULT '{}',
    "requestedById" TEXT NOT NULL,
    "addresseeId" TEXT NOT NULL,
    "status" "ApprovalStatus" NOT NULL DEFAULT 'pending',
    "attemptNumber" INTEGER NOT NULL DEFAULT 1,
    "decidedAt" TIMESTAMP(3),
    "decidedById" TEXT,
    "decisionComment" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Approval_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ApprovalAttempt" (
    "id" TEXT NOT NULL,
    "approvalId" TEXT NOT NULL,
    "attemptNumber" INTEGER NOT NULL,
    "action" TEXT NOT NULL,
    "actorId" TEXT NOT NULL,
    "comment" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ApprovalAttempt_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ApprovalAttachment" (
    "id" TEXT NOT NULL,
    "approvalId" TEXT NOT NULL,
    "fileKey" TEXT NOT NULL,
    "thumbKey" TEXT,
    "mimeType" TEXT NOT NULL,
    "sizeBytes" INTEGER NOT NULL,
    "uploadedBy" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ApprovalAttachment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MethodologySection" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "orderIndex" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MethodologySection_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MethodologyArticle" (
    "id" TEXT NOT NULL,
    "sectionId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "orderIndex" INTEGER NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "etag" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MethodologyArticle_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ReferencePhoto" (
    "id" TEXT NOT NULL,
    "articleId" TEXT NOT NULL,
    "fileKey" TEXT NOT NULL,
    "caption" TEXT,
    "orderIndex" INTEGER NOT NULL,

    CONSTRAINT "ReferencePhoto_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Approval_projectId_status_idx" ON "Approval"("projectId", "status");

-- CreateIndex
CREATE INDEX "Approval_addresseeId_status_idx" ON "Approval"("addresseeId", "status");

-- CreateIndex
CREATE INDEX "Approval_stageId_idx" ON "Approval"("stageId");

-- CreateIndex
CREATE INDEX "Approval_stepId_idx" ON "Approval"("stepId");

-- CreateIndex
CREATE INDEX "Approval_scope_status_idx" ON "Approval"("scope", "status");

-- CreateIndex
CREATE INDEX "ApprovalAttempt_approvalId_createdAt_idx" ON "ApprovalAttempt"("approvalId", "createdAt");

-- CreateIndex
CREATE INDEX "ApprovalAttachment_approvalId_idx" ON "ApprovalAttachment"("approvalId");

-- CreateIndex
CREATE INDEX "MethodologySection_orderIndex_idx" ON "MethodologySection"("orderIndex");

-- CreateIndex
CREATE INDEX "MethodologyArticle_sectionId_orderIndex_idx" ON "MethodologyArticle"("sectionId", "orderIndex");

-- CreateIndex
CREATE INDEX "ReferencePhoto_articleId_orderIndex_idx" ON "ReferencePhoto"("articleId", "orderIndex");

-- AddForeignKey
ALTER TABLE "Approval" ADD CONSTRAINT "Approval_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Approval" ADD CONSTRAINT "Approval_stageId_fkey" FOREIGN KEY ("stageId") REFERENCES "Stage"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Approval" ADD CONSTRAINT "Approval_stepId_fkey" FOREIGN KEY ("stepId") REFERENCES "Step"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ApprovalAttempt" ADD CONSTRAINT "ApprovalAttempt_approvalId_fkey" FOREIGN KEY ("approvalId") REFERENCES "Approval"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ApprovalAttachment" ADD CONSTRAINT "ApprovalAttachment_approvalId_fkey" FOREIGN KEY ("approvalId") REFERENCES "Approval"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MethodologyArticle" ADD CONSTRAINT "MethodologyArticle_sectionId_fkey" FOREIGN KEY ("sectionId") REFERENCES "MethodologySection"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ReferencePhoto" ADD CONSTRAINT "ReferencePhoto_articleId_fkey" FOREIGN KEY ("articleId") REFERENCES "MethodologyArticle"("id") ON DELETE CASCADE ON UPDATE CASCADE;
