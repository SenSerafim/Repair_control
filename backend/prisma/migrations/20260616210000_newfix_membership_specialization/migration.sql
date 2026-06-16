-- Серафим 08.06.2026: специализация мастера (опционально).
ALTER TABLE "Membership" ADD COLUMN "specialization" TEXT;

-- Серафим 08.06.2026: новый kind ленты — удаление заявки на материалы.
ALTER TYPE "FeedEventKind" ADD VALUE IF NOT EXISTS 'material_request_deleted';
