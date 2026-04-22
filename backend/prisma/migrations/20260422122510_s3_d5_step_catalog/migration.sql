-- CreateEnum
CREATE TYPE "StepType" AS ENUM ('regular', 'extra');

-- CreateEnum
CREATE TYPE "ExtraApprovalStatus" AS ENUM ('pending', 'approved', 'rejected');

-- CreateEnum
CREATE TYPE "NoteScope" AS ENUM ('personal', 'forMe', 'stage');

-- CreateEnum
CREATE TYPE "QuestionStatus" AS ENUM ('open', 'answered', 'closed');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "FeedEventKind" ADD VALUE 'step_created';
ALTER TYPE "FeedEventKind" ADD VALUE 'step_reordered';
ALTER TYPE "FeedEventKind" ADD VALUE 'step_done';
ALTER TYPE "FeedEventKind" ADD VALUE 'step_reopened';
ALTER TYPE "FeedEventKind" ADD VALUE 'step_deleted';
ALTER TYPE "FeedEventKind" ADD VALUE 'substep_created';
ALTER TYPE "FeedEventKind" ADD VALUE 'substep_updated';
ALTER TYPE "FeedEventKind" ADD VALUE 'substep_deleted';
ALTER TYPE "FeedEventKind" ADD VALUE 'substep_done';
ALTER TYPE "FeedEventKind" ADD VALUE 'substep_reopened';
ALTER TYPE "FeedEventKind" ADD VALUE 'step_photo_added';
ALTER TYPE "FeedEventKind" ADD VALUE 'step_photo_deleted';
ALTER TYPE "FeedEventKind" ADD VALUE 'extra_work_requested';
ALTER TYPE "FeedEventKind" ADD VALUE 'extra_work_approved';
ALTER TYPE "FeedEventKind" ADD VALUE 'extra_work_rejected';
ALTER TYPE "FeedEventKind" ADD VALUE 'note_created';
ALTER TYPE "FeedEventKind" ADD VALUE 'note_updated';
ALTER TYPE "FeedEventKind" ADD VALUE 'note_deleted';
ALTER TYPE "FeedEventKind" ADD VALUE 'question_created';
ALTER TYPE "FeedEventKind" ADD VALUE 'question_answered';
ALTER TYPE "FeedEventKind" ADD VALUE 'question_closed';
ALTER TYPE "FeedEventKind" ADD VALUE 'stage_progress_recalculated';

-- CreateTable
CREATE TABLE "Step" (
    "id" TEXT NOT NULL,
    "stageId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "orderIndex" INTEGER NOT NULL,
    "type" "StepType" NOT NULL DEFAULT 'regular',
    "price" BIGINT,
    "doneAt" TIMESTAMP(3),
    "doneBy" TEXT,
    "extraQty" INTEGER,
    "extraUnitPrice" BIGINT,
    "extraApprovalStatus" "ExtraApprovalStatus",
    "extraApprovedBy" TEXT,
    "extraApprovedAt" TIMESTAMP(3),
    "extraRejectionReason" TEXT,
    "createdBy" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Step_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Substep" (
    "id" TEXT NOT NULL,
    "stepId" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "isDone" BOOLEAN NOT NULL DEFAULT false,
    "doneAt" TIMESTAMP(3),
    "doneBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Substep_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StepPhoto" (
    "id" TEXT NOT NULL,
    "stepId" TEXT NOT NULL,
    "fileKey" TEXT NOT NULL,
    "thumbKey" TEXT,
    "mimeType" TEXT NOT NULL,
    "size" BIGINT NOT NULL,
    "width" INTEGER,
    "height" INTEGER,
    "uploadedBy" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "StepPhoto_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Note" (
    "id" TEXT NOT NULL,
    "scope" "NoteScope" NOT NULL,
    "authorId" TEXT NOT NULL,
    "addresseeId" TEXT,
    "projectId" TEXT,
    "stageId" TEXT,
    "text" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Note_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Question" (
    "id" TEXT NOT NULL,
    "stepId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "addresseeId" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "status" "QuestionStatus" NOT NULL DEFAULT 'open',
    "answerText" TEXT,
    "answeredBy" TEXT,
    "answeredAt" TIMESTAMP(3),
    "closedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Question_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Step_stageId_orderIndex_idx" ON "Step"("stageId", "orderIndex");

-- CreateIndex
CREATE INDEX "Step_type_extraApprovalStatus_idx" ON "Step"("type", "extraApprovalStatus");

-- CreateIndex
CREATE INDEX "Step_doneAt_idx" ON "Step"("doneAt");

-- CreateIndex
CREATE INDEX "Substep_stepId_createdAt_idx" ON "Substep"("stepId", "createdAt");

-- CreateIndex
CREATE INDEX "Substep_authorId_idx" ON "Substep"("authorId");

-- CreateIndex
CREATE INDEX "StepPhoto_stepId_createdAt_idx" ON "StepPhoto"("stepId", "createdAt");

-- CreateIndex
CREATE INDEX "Note_authorId_createdAt_idx" ON "Note"("authorId", "createdAt");

-- CreateIndex
CREATE INDEX "Note_addresseeId_createdAt_idx" ON "Note"("addresseeId", "createdAt");

-- CreateIndex
CREATE INDEX "Note_stageId_createdAt_idx" ON "Note"("stageId", "createdAt");

-- CreateIndex
CREATE INDEX "Note_projectId_createdAt_idx" ON "Note"("projectId", "createdAt");

-- CreateIndex
CREATE INDEX "Question_stepId_createdAt_idx" ON "Question"("stepId", "createdAt");

-- CreateIndex
CREATE INDEX "Question_addresseeId_status_idx" ON "Question"("addresseeId", "status");

-- CreateIndex
CREATE INDEX "Question_authorId_status_idx" ON "Question"("authorId", "status");

-- AddForeignKey
ALTER TABLE "Step" ADD CONSTRAINT "Step_stageId_fkey" FOREIGN KEY ("stageId") REFERENCES "Stage"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Substep" ADD CONSTRAINT "Substep_stepId_fkey" FOREIGN KEY ("stepId") REFERENCES "Step"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StepPhoto" ADD CONSTRAINT "StepPhoto_stepId_fkey" FOREIGN KEY ("stepId") REFERENCES "Step"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Note" ADD CONSTRAINT "Note_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Note" ADD CONSTRAINT "Note_stageId_fkey" FOREIGN KEY ("stageId") REFERENCES "Stage"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Question" ADD CONSTRAINT "Question_stepId_fkey" FOREIGN KEY ("stepId") REFERENCES "Step"("id") ON DELETE CASCADE ON UPDATE CASCADE;
