-- E1a — Заявки 2.0
-- ТЗ NEWFIX §5.7: расширение FSM (accepted_partial/full), фото и дедлайн позиции, события ленты.
--
-- Изменения:
--   1) MaterialRequestStatus +accepted_partial, +accepted_full
--   2) MaterialItem +actualQty, +dueDate (+ индекс по dueDate для cron-сканера overdue)
--   3) Новая таблица MaterialItemPhoto (1:1 на позицию)
--   4) FeedEventKind +material_request_accepted_partial / _full / _overdue

-- 1) Расширение enum MaterialRequestStatus
ALTER TYPE "MaterialRequestStatus" ADD VALUE IF NOT EXISTS 'accepted_partial';
ALTER TYPE "MaterialRequestStatus" ADD VALUE IF NOT EXISTS 'accepted_full';

-- 2) Новые поля в MaterialItem
ALTER TABLE "MaterialItem"
  ADD COLUMN IF NOT EXISTS "actualQty" DECIMAL(12, 3),
  ADD COLUMN IF NOT EXISTS "dueDate"   TIMESTAMP(3);

CREATE INDEX IF NOT EXISTS "MaterialItem_dueDate_idx"
  ON "MaterialItem" ("dueDate");

-- 3) MaterialItemPhoto — одно фото на позицию (1:1 через UNIQUE itemId)
CREATE TABLE IF NOT EXISTS "MaterialItemPhoto" (
  "id"          TEXT          NOT NULL,
  "itemId"      TEXT          NOT NULL,
  "fileKey"     TEXT          NOT NULL,
  "thumbKey"    TEXT,
  "mimeType"    TEXT          NOT NULL,
  "sizeBytes"   INTEGER       NOT NULL,
  "uploadedBy"  TEXT          NOT NULL,
  "exifCleared" BOOLEAN       NOT NULL DEFAULT false,
  "createdAt"   TIMESTAMP(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "MaterialItemPhoto_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "MaterialItemPhoto_itemId_key"
  ON "MaterialItemPhoto" ("itemId");

ALTER TABLE "MaterialItemPhoto"
  ADD CONSTRAINT "MaterialItemPhoto_itemId_fkey"
  FOREIGN KEY ("itemId") REFERENCES "MaterialItem" ("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

-- 4) Новые feed-события
ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'material_request_accepted_partial';
ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'material_request_accepted_full';
ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'material_request_overdue';
