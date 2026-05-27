-- Simplified tools (2026-05-12).
--
-- Старый flow: ToolItem (totalQty/issuedQty) + ToolIssuance (FSM из 7 статусов).
-- Новый flow: один ToolItem = один физический инструмент (qty=1) с полем
--             `currentHolderId` (у кого сейчас) + immutable лог ToolCustodyEvent.
--             Никто не назначает инструмент другому — только self-claim.
--
-- Шаги:
--   1) Сносим таблицу ToolIssuance и enum ToolIssuanceStatus.
--   2) В ToolItem убираем totalQty/issuedQty/unit, добавляем currentHolderId.
--      Backfill: currentHolderId = ownerId для всех существующих записей.
--   3) Создаём ToolCustodyEvent (history-лог передач).
--   4) Расширяем FeedEventKind / NotificationKind новыми значениями.

-- 1) Снос ToolIssuance.
DROP TABLE IF EXISTS "ToolIssuance";
DROP TYPE  IF EXISTS "ToolIssuanceStatus";

-- 2) ToolItem: убрать qty-поля, добавить currentHolderId.
ALTER TABLE "ToolItem" DROP COLUMN IF EXISTS "totalQty";
ALTER TABLE "ToolItem" DROP COLUMN IF EXISTS "issuedQty";
ALTER TABLE "ToolItem" DROP COLUMN IF EXISTS "unit";

ALTER TABLE "ToolItem" ADD COLUMN "currentHolderId" TEXT;
UPDATE "ToolItem" SET "currentHolderId" = "ownerId" WHERE "currentHolderId" IS NULL;
ALTER TABLE "ToolItem" ALTER COLUMN "currentHolderId" SET NOT NULL;

CREATE INDEX IF NOT EXISTS "ToolItem_currentHolderId_idx" ON "ToolItem"("currentHolderId");

-- 3) ToolCustodyEvent — иммутабельный лог передач.
CREATE TABLE "ToolCustodyEvent" (
  "id"               TEXT NOT NULL,
  "toolItemId"       TEXT NOT NULL,
  "projectId"        TEXT NOT NULL,
  "holderId"         TEXT NOT NULL,
  "previousHolderId" TEXT,
  "note"             TEXT,
  "createdAt"        TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "ToolCustodyEvent_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "ToolCustodyEvent"
  ADD CONSTRAINT "ToolCustodyEvent_toolItemId_fkey"
  FOREIGN KEY ("toolItemId") REFERENCES "ToolItem"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

CREATE INDEX "ToolCustodyEvent_toolItemId_createdAt_idx"
  ON "ToolCustodyEvent"("toolItemId", "createdAt");
CREATE INDEX "ToolCustodyEvent_projectId_createdAt_idx"
  ON "ToolCustodyEvent"("projectId", "createdAt");
CREATE INDEX "ToolCustodyEvent_holderId_idx"
  ON "ToolCustodyEvent"("holderId");

-- Backfill: для каждого ToolItem с projectId создаём initial-событие
-- (previousHolderId = NULL → это первое событие "ownerId стал holder при создании").
INSERT INTO "ToolCustodyEvent" ("id", "toolItemId", "projectId", "holderId", "previousHolderId", "note", "createdAt")
SELECT
  'cuid_seed_' || "id",   -- псевдо-cuid, не валидируется приложением (это backfill)
  "id",
  "projectId",
  "currentHolderId",
  NULL,
  NULL,
  "createdAt"
FROM "ToolItem"
WHERE "projectId" IS NOT NULL;

-- 4) Новые feed-kinds и notification-kind.
ALTER TYPE "FeedEventKind"    ADD VALUE IF NOT EXISTS 'tool_added_to_project';
ALTER TYPE "FeedEventKind"    ADD VALUE IF NOT EXISTS 'tool_removed_from_project';
ALTER TYPE "FeedEventKind"    ADD VALUE IF NOT EXISTS 'tool_custody_changed';
ALTER TYPE "NotificationKind" ADD VALUE IF NOT EXISTS 'tool_custody_changed';
