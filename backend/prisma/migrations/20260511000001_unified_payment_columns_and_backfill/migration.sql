-- 2026-05 рефактор: расширение Payment до единого ledger.
-- ТЗ §8 — двустороннее подтверждение (кто подтвердил) + унификация SelfPurchase и
-- Approval(extra_work) в Payment-таблицу с обратной ссылкой source* для аудита.

-- Pgcrypto нужно для gen_random_uuid() в backfill (id рассчитываем средствами БД,
-- т.к. cuid Prisma — клиентская функция; для backfill достаточно случайной строки).
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1) Новые поля Payment.
ALTER TABLE "Payment"
  ADD COLUMN IF NOT EXISTS "confirmedBy" TEXT,
  ADD COLUMN IF NOT EXISTS "sourceTable" TEXT,
  ADD COLUMN IF NOT EXISTS "sourceId"    TEXT;

-- 2) Индексы и уникальное ограничение (нужно для idempotent-backfill).
CREATE UNIQUE INDEX IF NOT EXISTS "Payment_sourceTable_sourceId_key"
  ON "Payment"("sourceTable", "sourceId")
  WHERE "sourceTable" IS NOT NULL AND "sourceId" IS NOT NULL;

CREATE INDEX IF NOT EXISTS "Payment_confirmedBy_idx" ON "Payment"("confirmedBy");

-- 3) Backfill: SelfPurchase(approved, byRole=foreman) → Payment(kind=selfpurchase).
-- foreman-самозакуп — единственный, который попадает в бюджет проекта; master-копия
-- (с forwardedFromId) идёт через foreman и в ledger не дублируется.
INSERT INTO "Payment"
  ("id", "projectId", "stageId", "kind", "fromUserId", "toUserId", "amount", "status",
   "confirmedAt", "confirmedBy", "sourceTable", "sourceId", "createdAt", "updatedAt")
SELECT
  gen_random_uuid()::text,
  sp."projectId",
  sp."stageId",
  'selfpurchase'::"PaymentKind",
  sp."byUserId",
  sp."byUserId",          -- toUserId = byUserId: списание у самого инициатора
  sp."amount",
  'confirmed'::"PaymentStatus",
  sp."decidedAt",
  sp."decidedById",
  'self_purchase',
  sp."id",
  sp."createdAt",
  sp."updatedAt"
FROM "SelfPurchase" sp
WHERE sp."status" = 'approved'
  AND sp."byRole" = 'foreman'
  AND NOT EXISTS (
    SELECT 1 FROM "Payment" p
    WHERE p."sourceTable" = 'self_purchase' AND p."sourceId" = sp."id"
  );

-- 4) Backfill: Approval(scope=extra_work, status=approved) → Payment(kind=extra_work).
-- amount берётся из payload.price (int кoпейки).
INSERT INTO "Payment"
  ("id", "projectId", "stageId", "kind", "fromUserId", "toUserId", "amount", "status",
   "confirmedAt", "confirmedBy", "sourceTable", "sourceId", "createdAt", "updatedAt")
SELECT
  gen_random_uuid()::text,
  a."projectId",
  a."stageId",
  'extra_work'::"PaymentKind",
  a."requestedById",
  a."requestedById",
  COALESCE(NULLIF(a."payload" ->> 'price', '')::bigint, 0),
  'confirmed'::"PaymentStatus",
  a."decidedAt",
  a."decidedById",
  'approval_extra_work',
  a."id",
  a."createdAt",
  a."updatedAt"
FROM "Approval" a
WHERE a."scope" = 'extra_work'::"ApprovalScope"
  AND a."status" = 'approved'::"ApprovalStatus"
  AND NOT EXISTS (
    SELECT 1 FROM "Payment" p
    WHERE p."sourceTable" = 'approval_extra_work' AND p."sourceId" = a."id"
  );

-- 5) Заполнить confirmedBy для исторически подтверждённых платежей.
-- Источник истины — ApprovalAttempt(action='approved') для соответствующих payment_dispute,
-- но напрямую этой связки в Payment нет. Используем эвристику:
--   - для kind=advance/distribution/final: confirmedBy = toUserId, если status IN ('confirmed','resolved').
--     Это безопасно — confirm может выполнить только получатель (см. payments.service.confirm).
UPDATE "Payment"
SET "confirmedBy" = "toUserId"
WHERE "confirmedBy" IS NULL
  AND "status" IN ('confirmed', 'resolved')
  AND "kind" IN ('advance', 'distribution', 'final', 'correction');
