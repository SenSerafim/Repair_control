-- S5: Chat, Documents, Notifications (FCM), FAQ, Feedback, AppSettings, Export jobs.
-- Примечание: DROP INDEX "methodology_article_trgm_idx" из prisma migrate diff НЕ выполняем —
-- это ручной GIN-индекс из миграции S3 (см. 20260420105919_add_methodology_fts), Prisma про него не знает.
-- В конце файла перестраховочно CREATE EXTENSION/INDEX IF NOT EXISTS.

-- CreateEnum
CREATE TYPE "ChatType" AS ENUM ('project', 'stage', 'personal', 'group');

-- CreateEnum
CREATE TYPE "DocumentCategory" AS ENUM ('contract', 'act', 'estimate', 'warranty', 'photo', 'blueprint', 'other');

-- CreateEnum
CREATE TYPE "NotificationKind" AS ENUM ('approval_requested', 'approval_approved', 'approval_rejected', 'payment_created', 'payment_confirmed', 'payment_disputed', 'payment_resolved', 'stage_rejected_by_customer', 'stage_overdue', 'stage_deadline_exceeds_project', 'material_request_created', 'material_delivered', 'material_disputed', 'selfpurchase_created', 'tool_issued', 'export_completed', 'export_failed', 'chat_message_new', 'step_completed', 'stage_completed', 'stage_paused', 'note_created_for_me', 'question_asked', 'project_archived', 'membership_added');

-- CreateEnum
CREATE TYPE "NotificationPriority" AS ENUM ('critical', 'high', 'normal');

-- CreateEnum
CREATE TYPE "ExportKind" AS ENUM ('feed_pdf', 'project_zip');

-- CreateEnum
CREATE TYPE "ExportStatus" AS ENUM ('queued', 'running', 'done', 'failed', 'expired');

-- AlterEnum: FeedEventKind += S5 events
ALTER TYPE "FeedEventKind" ADD VALUE 'chat_created';
ALTER TYPE "FeedEventKind" ADD VALUE 'chat_message_sent';
ALTER TYPE "FeedEventKind" ADD VALUE 'chat_participant_added';
ALTER TYPE "FeedEventKind" ADD VALUE 'chat_participant_removed';
ALTER TYPE "FeedEventKind" ADD VALUE 'chat_visibility_toggled';
ALTER TYPE "FeedEventKind" ADD VALUE 'document_uploaded';
ALTER TYPE "FeedEventKind" ADD VALUE 'document_updated';
ALTER TYPE "FeedEventKind" ADD VALUE 'document_deleted';
ALTER TYPE "FeedEventKind" ADD VALUE 'export_requested';
ALTER TYPE "FeedEventKind" ADD VALUE 'export_completed';
ALTER TYPE "FeedEventKind" ADD VALUE 'export_failed';
ALTER TYPE "FeedEventKind" ADD VALUE 'feedback_received';
ALTER TYPE "FeedEventKind" ADD VALUE 'admin_settings_updated';
ALTER TYPE "FeedEventKind" ADD VALUE 'admin_faq_updated';
ALTER TYPE "FeedEventKind" ADD VALUE 'admin_methodology_updated';
ALTER TYPE "FeedEventKind" ADD VALUE 'admin_template_updated';

-- CreateTable
CREATE TABLE "Chat" (
    "id" TEXT NOT NULL,
    "type" "ChatType" NOT NULL,
    "projectId" TEXT,
    "stageId" TEXT,
    "title" TEXT,
    "visibleToCustomer" BOOLEAN NOT NULL DEFAULT false,
    "createdById" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "archivedAt" TIMESTAMP(3),

    CONSTRAINT "Chat_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ChatParticipant" (
    "id" TEXT NOT NULL,
    "chatId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "leftAt" TIMESTAMP(3),
    "lastReadMessageId" TEXT,
    "lastReadAt" TIMESTAMP(3),
    "mutedUntil" TIMESTAMP(3),

    CONSTRAINT "ChatParticipant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ChatMessage" (
    "id" TEXT NOT NULL,
    "chatId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "text" TEXT,
    "attachmentKeys" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "forwardedFromId" TEXT,
    "editedAt" TIMESTAMP(3),
    "deletedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ChatMessage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Document" (
    "id" TEXT NOT NULL,
    "projectId" TEXT NOT NULL,
    "stageId" TEXT,
    "stepId" TEXT,
    "category" "DocumentCategory" NOT NULL,
    "title" TEXT NOT NULL,
    "fileKey" TEXT NOT NULL,
    "thumbKey" TEXT,
    "thumbStatus" TEXT NOT NULL DEFAULT 'pending',
    "mimeType" TEXT NOT NULL,
    "sizeBytes" INTEGER NOT NULL,
    "uploadedById" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Document_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "NotificationSetting" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "kind" "NotificationKind" NOT NULL,
    "pushEnabled" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "NotificationSetting_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "NotificationLog" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "deviceTokenId" TEXT,
    "kind" "NotificationKind" NOT NULL,
    "priority" "NotificationPriority" NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "deepLink" TEXT,
    "projectId" TEXT,
    "payload" JSONB NOT NULL DEFAULT '{}',
    "sentAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deliveredAt" TIMESTAMP(3),
    "failedAt" TIMESTAMP(3),
    "failureReason" TEXT,

    CONSTRAINT "NotificationLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FaqSection" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "orderIndex" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "FaqSection_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FaqItem" (
    "id" TEXT NOT NULL,
    "sectionId" TEXT NOT NULL,
    "question" TEXT NOT NULL,
    "answer" TEXT NOT NULL,
    "orderIndex" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "FaqItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FeedbackMessage" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "attachmentKeys" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "status" TEXT NOT NULL DEFAULT 'new',
    "readById" TEXT,
    "readAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "FeedbackMessage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AppSetting" (
    "key" TEXT NOT NULL,
    "value" TEXT NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "updatedBy" TEXT,

    CONSTRAINT "AppSetting_pkey" PRIMARY KEY ("key")
);

-- CreateTable
CREATE TABLE "ExportJob" (
    "id" TEXT NOT NULL,
    "projectId" TEXT NOT NULL,
    "requestedById" TEXT NOT NULL,
    "kind" "ExportKind" NOT NULL,
    "filtersPayload" JSONB NOT NULL DEFAULT '{}',
    "status" "ExportStatus" NOT NULL DEFAULT 'queued',
    "progressPct" INTEGER NOT NULL DEFAULT 0,
    "resultFileKey" TEXT,
    "resultSizeBytes" INTEGER,
    "error" TEXT,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "startedAt" TIMESTAMP(3),
    "finishedAt" TIMESTAMP(3),

    CONSTRAINT "ExportJob_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Chat_projectId_createdAt_idx" ON "Chat"("projectId", "createdAt");

-- CreateIndex
CREATE INDEX "Chat_stageId_idx" ON "Chat"("stageId");

-- CreateIndex
CREATE INDEX "Chat_type_idx" ON "Chat"("type");

-- CreateIndex
CREATE INDEX "ChatParticipant_userId_leftAt_idx" ON "ChatParticipant"("userId", "leftAt");

-- CreateIndex
CREATE UNIQUE INDEX "ChatParticipant_chatId_userId_key" ON "ChatParticipant"("chatId", "userId");

-- CreateIndex
CREATE INDEX "ChatMessage_chatId_createdAt_idx" ON "ChatMessage"("chatId", "createdAt");

-- CreateIndex
CREATE INDEX "ChatMessage_authorId_idx" ON "ChatMessage"("authorId");

-- CreateIndex
CREATE INDEX "Document_projectId_createdAt_idx" ON "Document"("projectId", "createdAt");

-- CreateIndex
CREATE INDEX "Document_stageId_idx" ON "Document"("stageId");

-- CreateIndex
CREATE INDEX "Document_stepId_idx" ON "Document"("stepId");

-- CreateIndex
CREATE INDEX "Document_category_idx" ON "Document"("category");

-- CreateIndex
CREATE INDEX "NotificationSetting_userId_idx" ON "NotificationSetting"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "NotificationSetting_userId_kind_key" ON "NotificationSetting"("userId", "kind");

-- CreateIndex
CREATE INDEX "NotificationLog_userId_sentAt_idx" ON "NotificationLog"("userId", "sentAt");

-- CreateIndex
CREATE INDEX "NotificationLog_projectId_sentAt_idx" ON "NotificationLog"("projectId", "sentAt");

-- CreateIndex
CREATE INDEX "NotificationLog_kind_idx" ON "NotificationLog"("kind");

-- CreateIndex
CREATE INDEX "FaqSection_orderIndex_idx" ON "FaqSection"("orderIndex");

-- CreateIndex
CREATE INDEX "FaqItem_sectionId_orderIndex_idx" ON "FaqItem"("sectionId", "orderIndex");

-- CreateIndex
CREATE INDEX "FeedbackMessage_userId_createdAt_idx" ON "FeedbackMessage"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "FeedbackMessage_status_createdAt_idx" ON "FeedbackMessage"("status", "createdAt");

-- CreateIndex
CREATE INDEX "ExportJob_projectId_status_idx" ON "ExportJob"("projectId", "status");

-- CreateIndex
CREATE INDEX "ExportJob_requestedById_createdAt_idx" ON "ExportJob"("requestedById", "createdAt");

-- CreateIndex
CREATE INDEX "ExportJob_expiresAt_idx" ON "ExportJob"("expiresAt");

-- AddForeignKey
ALTER TABLE "Chat" ADD CONSTRAINT "Chat_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Chat" ADD CONSTRAINT "Chat_stageId_fkey" FOREIGN KEY ("stageId") REFERENCES "Stage"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatParticipant" ADD CONSTRAINT "ChatParticipant_chatId_fkey" FOREIGN KEY ("chatId") REFERENCES "Chat"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatMessage" ADD CONSTRAINT "ChatMessage_chatId_fkey" FOREIGN KEY ("chatId") REFERENCES "Chat"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatMessage" ADD CONSTRAINT "ChatMessage_forwardedFromId_fkey" FOREIGN KEY ("forwardedFromId") REFERENCES "ChatMessage"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Document" ADD CONSTRAINT "Document_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FaqItem" ADD CONSTRAINT "FaqItem_sectionId_fkey" FOREIGN KEY ("sectionId") REFERENCES "FaqSection"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExportJob" ADD CONSTRAINT "ExportJob_projectId_fkey" FOREIGN KEY ("projectId") REFERENCES "Project"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Защитный re-create ручного trgm-индекса на методичке (S3 миграция).
-- Prisma migrate diff пытается его сдропнуть — не позволяем.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS "methodology_article_trgm_idx"
  ON "MethodologyArticle" USING GIN ("title" gin_trgm_ops);
