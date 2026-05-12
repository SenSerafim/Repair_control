-- Упрощение жизненного цикла заявок на материалы (S19, 2026-05-11).
--
-- Старый FSM (8 статусов): draft → open → partially_bought → bought → delivered + disputed/resolved/cancelled.
-- Новый FSM (7 статусов): pending_approval → open → bought → delivered + disputed/resolved/cancelled.
--
-- Удалены:
--   - draft           — не нужен, заявка создаётся сразу видимой.
--                       Backfill: draft → cancelled (черновики, не дошедшие до отправки, безопасно отменяем).
--   - partially_bought — представимо через items.isBought + boughtItemsCount.
--                       Backfill: partially_bought → open.
--
-- Добавлен:
--   - pending_approval — заявка от foreman/master ждёт согласования заказчиком.
--
-- Default: было draft → стало pending_approval.

-- 1) Создаём новый enum.
CREATE TYPE "MaterialRequestStatus_new" AS ENUM (
  'pending_approval',
  'open',
  'bought',
  'delivered',
  'disputed',
  'resolved',
  'cancelled'
);

-- 2) Backfill: маппим старые значения на новые перед сменой типа.
--    Снимаем дефолт чтобы не мешал ALTER COLUMN.
ALTER TABLE "MaterialRequest" ALTER COLUMN "status" DROP DEFAULT;

ALTER TABLE "MaterialRequest"
  ALTER COLUMN "status" TYPE "MaterialRequestStatus_new"
  USING (
    CASE "status"::text
      WHEN 'draft'             THEN 'cancelled'
      WHEN 'partially_bought'  THEN 'open'
      ELSE "status"::text
    END
  )::"MaterialRequestStatus_new";

-- 3) Переименовываем enum.
ALTER TYPE "MaterialRequestStatus" RENAME TO "MaterialRequestStatus_old";
ALTER TYPE "MaterialRequestStatus_new" RENAME TO "MaterialRequestStatus";
DROP TYPE "MaterialRequestStatus_old";

-- 4) Восстанавливаем дефолт уже на новом enum.
ALTER TABLE "MaterialRequest" ALTER COLUMN "status" SET DEFAULT 'pending_approval';

-- 5) Новые feed-kinds (для approve/reject заявки на материалы).
ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'material_request_approved';
ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'material_request_cancelled';
