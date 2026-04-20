-- CreateEnum
CREATE TYPE "StepType" AS ENUM ('regular', 'extra');

-- CreateEnum
CREATE TYPE "StepStatus" AS ENUM ('pending', 'in_progress', 'done', 'pending_approval', 'rejected');

-- CreateEnum
CREATE TYPE "QuestionStatus" AS ENUM ('open', 'answered', 'closed');

-- CreateEnum
CREATE TYPE "NoteScope" AS ENUM ('personal', 'for_me', 'stage');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "FeedEventKind" ADD VALUE 'step_created';
ALTER TYPE "FeedEventKind" ADD VALUE 'step_updated';
ALTER TYPE "FeedEventKind" ADD VALUE 'step_completed';
ALTER TYPE "FeedEventKind" ADD VALUE 'step_uncompleted';
ALTER TYPE "FeedEventKind" ADD VALUE 'step_deleted';
ALTER TYPE "FeedEventKind" ADD VALUE 'steps_reordered';
ALTER TYPE "FeedEventKind" ADD VALUE 'substep_added';
ALTER TYPE "FeedEventKind" ADD VALUE 'substep_updated';
ALTER TYPE "FeedEventKind" ADD VALUE 'substep_completed';
ALTER TYPE "FeedEventKind" ADD VALUE 'substep_uncompleted';
ALTER TYPE "FeedEventKind" ADD VALUE 'substep_deleted';
ALTER TYPE "FeedEventKind" ADD VALUE 'photo_attached';
ALTER TYPE "FeedEventKind" ADD VALUE 'photo_deleted';
ALTER TYPE "FeedEventKind" ADD VALUE 'extra_work_requested';
ALTER TYPE "FeedEventKind" ADD VALUE 'note_created';
ALTER TYPE "FeedEventKind" ADD VALUE 'note_updated';
ALTER TYPE "FeedEventKind" ADD VALUE 'note_deleted';
ALTER TYPE "FeedEventKind" ADD VALUE 'question_asked';
ALTER TYPE "FeedEventKind" ADD VALUE 'question_answered';
ALTER TYPE "FeedEventKind" ADD VALUE 'question_closed';
ALTER TYPE "FeedEventKind" ADD VALUE 'progress_recalculated_on_step_change';

-- CreateTable
CREATE TABLE "Step" (
    "id" TEXT NOT NULL,
    "stageId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "orderIndex" INTEGER NOT NULL,
    "type" "StepType" NOT NULL DEFAULT 'regular',
    "status" "StepStatus" NOT NULL DEFAULT 'pending',
    "price" BIGINT,
    "description" TEXT,
    "authorId" TEXT NOT NULL,
    "assigneeIds" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "doneAt" TIMESTAMP(3),
    "doneById" TEXT,
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
    "doneById" TEXT,
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
    "sizeBytes" INTEGER NOT NULL,
    "uploadedBy" TEXT NOT NULL,
    "exifCleared" BOOLEAN NOT NULL DEFAULT false,
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
    "answer" TEXT,
    "answeredAt" TIMESTAMP(3),
    "answeredBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Question_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Step_stageId_orderIndex_idx" ON "Step"("stageId", "orderIndex");

-- CreateIndex
CREATE INDEX "Step_status_idx" ON "Step"("status");

-- CreateIndex
CREATE INDEX "Step_type_idx" ON "Step"("type");

-- CreateIndex
CREATE INDEX "Substep_stepId_idx" ON "Substep"("stepId");

-- CreateIndex
CREATE INDEX "Substep_authorId_idx" ON "Substep"("authorId");

-- CreateIndex
CREATE INDEX "StepPhoto_stepId_idx" ON "StepPhoto"("stepId");

-- CreateIndex
CREATE INDEX "Note_authorId_scope_createdAt_idx" ON "Note"("authorId", "scope", "createdAt");

-- CreateIndex
CREATE INDEX "Note_addresseeId_scope_idx" ON "Note"("addresseeId", "scope");

-- CreateIndex
CREATE INDEX "Note_stageId_idx" ON "Note"("stageId");

-- CreateIndex
CREATE INDEX "Note_projectId_idx" ON "Note"("projectId");

-- CreateIndex
CREATE INDEX "Question_stepId_status_idx" ON "Question"("stepId", "status");

-- CreateIndex
CREATE INDEX "Question_addresseeId_status_idx" ON "Question"("addresseeId", "status");

-- AddForeignKey
ALTER TABLE "Step" ADD CONSTRAINT "Step_stageId_fkey" FOREIGN KEY ("stageId") REFERENCES "Stage"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Substep" ADD CONSTRAINT "Substep_stepId_fkey" FOREIGN KEY ("stepId") REFERENCES "Step"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StepPhoto" ADD CONSTRAINT "StepPhoto_stepId_fkey" FOREIGN KEY ("stepId") REFERENCES "Step"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Question" ADD CONSTRAINT "Question_stepId_fkey" FOREIGN KEY ("stepId") REFERENCES "Step"("id") ON DELETE CASCADE ON UPDATE CASCADE;
