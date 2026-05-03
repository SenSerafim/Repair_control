-- ============================================================================
-- Comprehensive v2 fixes (2026-05-04) — see ПРОБЛЕМЫ_ТЕСТИРОВАНИЯ.md
-- Adds:
--   - NoteScope.team_broadcast (P1.10, P2.19)
--   - ToolIssuanceStatus.requested/approved/rejected (P2.15)
--   - ApprovalScope.stage_create/material_purchase/self_purchase/payment_dispute (P2.2, P2.3, P2.4)
--   - FeedEventKind/NotificationKind extensions (P10.3, P2.18)
--   - Membership.removedAt/removedById/hiddenForUser (P2.16)
--   - Stage.masterId/pendingApproval (P2.5, P2.4)
--   - Step.whatDid/howDid (P2.8)
--   - Approval.actorRole (P2.6)
--   - ToolItem.serial/projectId (P2.14, P2.15)
-- ============================================================================

-- ---------- Enum extensions ----------

ALTER TYPE "NoteScope" ADD VALUE IF NOT EXISTS 'team_broadcast';

ALTER TYPE "ToolIssuanceStatus" ADD VALUE IF NOT EXISTS 'requested';
ALTER TYPE "ToolIssuanceStatus" ADD VALUE IF NOT EXISTS 'approved';
ALTER TYPE "ToolIssuanceStatus" ADD VALUE IF NOT EXISTS 'rejected';

ALTER TYPE "ApprovalScope" ADD VALUE IF NOT EXISTS 'stage_create';
ALTER TYPE "ApprovalScope" ADD VALUE IF NOT EXISTS 'material_purchase';
ALTER TYPE "ApprovalScope" ADD VALUE IF NOT EXISTS 'self_purchase';
ALTER TYPE "ApprovalScope" ADD VALUE IF NOT EXISTS 'payment_dispute';

ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'foreman_assigned';
ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'master_assigned';
ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'master_unassigned';
ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'stage_pending_approval';
ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'budget_changed_by_customer';
ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'membership_left';
ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'membership_hidden';
ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'tool_requested';
ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'tool_request_approved';
ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'tool_request_rejected';
ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'tool_force_returned';

ALTER TYPE "NotificationKind" ADD VALUE IF NOT EXISTS 'stage_foreman_assigned';
ALTER TYPE "NotificationKind" ADD VALUE IF NOT EXISTS 'stage_master_assigned';
ALTER TYPE "NotificationKind" ADD VALUE IF NOT EXISTS 'stage_create_requested';
ALTER TYPE "NotificationKind" ADD VALUE IF NOT EXISTS 'material_purchase_requested';
ALTER TYPE "NotificationKind" ADD VALUE IF NOT EXISTS 'payment_dispute_requested';
ALTER TYPE "NotificationKind" ADD VALUE IF NOT EXISTS 'budget_changed';
ALTER TYPE "NotificationKind" ADD VALUE IF NOT EXISTS 'tool_request_created';
ALTER TYPE "NotificationKind" ADD VALUE IF NOT EXISTS 'tool_request_decided';

-- ---------- Membership: hide / leave ----------

ALTER TABLE "Membership"
  ADD COLUMN IF NOT EXISTS "removedAt"     TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "removedById"   TEXT,
  ADD COLUMN IF NOT EXISTS "hiddenForUser" BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS "Membership_removedAt_idx" ON "Membership"("removedAt");

-- ---------- Stage: master + pending approval ----------

ALTER TABLE "Stage"
  ADD COLUMN IF NOT EXISTS "masterId"        TEXT,
  ADD COLUMN IF NOT EXISTS "pendingApproval" BOOLEAN NOT NULL DEFAULT false;

-- ---------- Step: what/how did ----------

ALTER TABLE "Step"
  ADD COLUMN IF NOT EXISTS "whatDid" TEXT,
  ADD COLUMN IF NOT EXISTS "howDid"  TEXT;

-- ---------- Approval: actorRole ----------

ALTER TABLE "Approval"
  ADD COLUMN IF NOT EXISTS "actorRole" "MembershipRole";

-- ---------- ToolItem: serial + projectId ----------

ALTER TABLE "ToolItem"
  ADD COLUMN IF NOT EXISTS "serial"    TEXT,
  ADD COLUMN IF NOT EXISTS "projectId" TEXT;

CREATE INDEX IF NOT EXISTS "ToolItem_projectId_idx" ON "ToolItem"("projectId");
