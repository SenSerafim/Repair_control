-- Simplified payments (2026-05-12).
--
-- Старый flow: 5-статусная FSM (pending → confirmed → cancelled / disputed → resolved)
--              + PaymentDispute + mirror Approval(scope='payment_dispute').
-- Новый flow: создание платежа = факт передачи денег. Без подтверждений,
--             без отмены, без споров. Customer (или представитель) может
--             платить напрямую foreman или master; foreman из полученных
--             авансов распределяет деньги мастерам. Бюджет считается по
--             всем advance-записям проекта.
--
-- Шаги:
--   1) Снести PaymentDispute (включая cascade).
--   2) Удалить из Payment колонки: status, resolvedAmount, confirmedAt,
--      disputedAt, resolvedAt, cancelledAt. Удалить старый индекс,
--      создать новый по createdAt.
--   3) Удалить старые cancelled-платежи (их быть в проде не должно, БД в dev).
--   4) DROP TYPE "PaymentStatus".
--   5) Удалить устаревшие enum-значения через пересоздание типа:
--      ApprovalScope -- удалить 'payment_dispute' (попутно очистить осиротевшие
--      mirror-approvals и связанные approvalAttempts).
--      FeedEventKind -- удалить payment_confirmed/_cancelled/_disputed/_resolved.
--      NotificationKind -- удалить payment_confirmed/_disputed/_resolved/_dispute_requested.

-- 1) PaymentDispute полностью убираем.
DROP TABLE IF EXISTS "PaymentDispute";

-- 2) Чистим Payment.
--    Сначала прибиваем cancelled-платежи (исторические — отмена больше не поддерживается).
DELETE FROM "Payment" WHERE "status" = 'cancelled';

DROP INDEX IF EXISTS "Payment_projectId_status_idx";

ALTER TABLE "Payment" DROP COLUMN IF EXISTS "status";
ALTER TABLE "Payment" DROP COLUMN IF EXISTS "resolvedAmount";
ALTER TABLE "Payment" DROP COLUMN IF EXISTS "confirmedAt";
ALTER TABLE "Payment" DROP COLUMN IF EXISTS "disputedAt";
ALTER TABLE "Payment" DROP COLUMN IF EXISTS "resolvedAt";
ALTER TABLE "Payment" DROP COLUMN IF EXISTS "cancelledAt";

CREATE INDEX IF NOT EXISTS "Payment_projectId_createdAt_idx"
  ON "Payment"("projectId", "createdAt");

-- 3) Снос enum PaymentStatus.
DROP TYPE IF EXISTS "PaymentStatus";

-- 4) ApprovalScope: удалить 'payment_dispute'.
--    Сначала прибиваем все осиротевшие записи (approvalAttempt / approvalAttachment / approval).
DELETE FROM "ApprovalAttempt"
  WHERE "approvalId" IN (SELECT "id" FROM "Approval" WHERE "scope" = 'payment_dispute');
DELETE FROM "ApprovalAttachment"
  WHERE "approvalId" IN (SELECT "id" FROM "Approval" WHERE "scope" = 'payment_dispute');
DELETE FROM "Approval" WHERE "scope" = 'payment_dispute';

ALTER TYPE "ApprovalScope" RENAME TO "ApprovalScope_old";

CREATE TYPE "ApprovalScope" AS ENUM (
  'plan',
  'step',
  'extra_work',
  'deadline_change',
  'stage_accept',
  'stage_create',
  'material_purchase',
  'self_purchase'
);

ALTER TABLE "Approval"
  ALTER COLUMN "scope" TYPE "ApprovalScope"
  USING ("scope"::text::"ApprovalScope");

DROP TYPE "ApprovalScope_old";

-- 5) FeedEventKind: удалить payment_confirmed/_cancelled/_disputed/_resolved.
--    Чистим feed_events с этими видами (исторические записи — нерелевантны).
DELETE FROM "FeedEvent"
  WHERE "kind" IN ('payment_confirmed', 'payment_cancelled', 'payment_disputed', 'payment_resolved');

ALTER TYPE "FeedEventKind" RENAME TO "FeedEventKind_old";

CREATE TYPE "FeedEventKind" AS ENUM (
  'project_created',
  'project_archived',
  'project_restored',
  'project_copied',
  'membership_added',
  'membership_removed',
  'stage_created',
  'stage_started',
  'stage_paused',
  'stage_resumed',
  'stage_sent_to_review',
  'stage_deadline_recalculated',
  'stage_deadline_exceeds_project',
  'stages_reordered',
  'step_created',
  'step_updated',
  'step_completed',
  'step_uncompleted',
  'step_deleted',
  'steps_reordered',
  'substep_added',
  'substep_updated',
  'substep_completed',
  'substep_uncompleted',
  'substep_deleted',
  'photo_attached',
  'photo_deleted',
  'extra_work_requested',
  'note_created',
  'note_updated',
  'note_deleted',
  'question_asked',
  'question_answered',
  'question_closed',
  'progress_recalculated_on_step_change',
  'approval_requested',
  'approval_approved',
  'approval_rejected',
  'approval_cancelled',
  'approval_resubmitted',
  'plan_approved',
  'deadline_changed',
  'stage_accepted',
  'stage_rejected_by_customer',
  'budget_updated',
  'methodology_section_created',
  'methodology_section_updated',
  'methodology_section_deleted',
  'methodology_article_created',
  'methodology_article_updated',
  'methodology_article_deleted',
  'payment_created',
  'payment_distributed',
  'material_request_created',
  'material_request_sent',
  'material_request_approved',
  'material_request_cancelled',
  'material_item_bought',
  'material_request_finalized',
  'material_delivered',
  'material_disputed',
  'material_resolved',
  'selfpurchase_created',
  'selfpurchase_approved',
  'selfpurchase_rejected',
  'selfpurchase_forwarded',
  'tool_issued',
  'tool_issuance_confirmed',
  'tool_return_requested',
  'tool_returned',
  'foreman_removed',
  'foreman_replaced',
  'foreman_assigned',
  'master_assigned',
  'master_unassigned',
  'stage_budget_edit_after_start',
  'stage_pending_approval',
  'budget_changed_by_customer',
  'membership_left',
  'membership_hidden',
  'tool_requested',
  'tool_request_approved',
  'tool_request_rejected',
  'tool_force_returned',
  'tool_added_to_project',
  'tool_removed_from_project',
  'tool_custody_changed',
  'chat_created',
  'chat_message_sent',
  'chat_participant_added',
  'chat_participant_removed',
  'chat_visibility_toggled',
  'document_uploaded',
  'document_updated',
  'document_deleted',
  'export_requested',
  'export_completed',
  'export_failed',
  'feedback_received',
  'admin_settings_updated',
  'admin_faq_updated',
  'admin_methodology_updated',
  'admin_template_updated'
);

ALTER TABLE "FeedEvent"
  ALTER COLUMN "kind" TYPE "FeedEventKind"
  USING ("kind"::text::"FeedEventKind");

DROP TYPE "FeedEventKind_old";

-- 6) NotificationKind: удалить payment_confirmed/_disputed/_resolved/_dispute_requested.
--    Чистим NotificationLog и NotificationSetting с этими видами.
DELETE FROM "NotificationLog"
  WHERE "kind" IN ('payment_confirmed', 'payment_disputed', 'payment_resolved', 'payment_dispute_requested');
DELETE FROM "NotificationSetting"
  WHERE "kind" IN ('payment_confirmed', 'payment_disputed', 'payment_resolved', 'payment_dispute_requested');

ALTER TYPE "NotificationKind" RENAME TO "NotificationKind_old";

CREATE TYPE "NotificationKind" AS ENUM (
  'approval_requested',
  'approval_approved',
  'approval_rejected',
  'payment_created',
  'stage_rejected_by_customer',
  'stage_overdue',
  'stage_deadline_exceeds_project',
  'material_request_created',
  'material_delivered',
  'material_disputed',
  'selfpurchase_created',
  'tool_issued',
  'export_completed',
  'export_failed',
  'chat_message_new',
  'step_completed',
  'stage_completed',
  'stage_paused',
  'note_created_for_me',
  'question_asked',
  'project_archived',
  'membership_added',
  'admin_announcement',
  'stage_foreman_assigned',
  'stage_master_assigned',
  'stage_create_requested',
  'material_purchase_requested',
  'budget_changed',
  'tool_request_created',
  'tool_request_decided',
  'tool_custody_changed'
);

ALTER TABLE "NotificationLog"
  ALTER COLUMN "kind" TYPE "NotificationKind"
  USING ("kind"::text::"NotificationKind");

ALTER TABLE "NotificationSetting"
  ALTER COLUMN "kind" TYPE "NotificationKind"
  USING ("kind"::text::"NotificationKind");

DROP TYPE "NotificationKind_old";
