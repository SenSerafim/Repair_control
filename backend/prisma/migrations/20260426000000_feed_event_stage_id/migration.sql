-- AlterTable: добавляем колонку stageId в FeedEvent для role-based фильтрации (TODO §2A.2 P0.7.d).
ALTER TABLE "FeedEvent" ADD COLUMN "stageId" TEXT;

-- Бэкфилл из payload.stageId, чтобы существующие события стали корректно фильтруемыми.
UPDATE "FeedEvent"
SET "stageId" = payload->>'stageId'
WHERE payload ? 'stageId' AND "stageId" IS NULL;

-- Индекс для запросов "events of project X for assigned stages".
CREATE INDEX "FeedEvent_projectId_stageId_createdAt_idx"
  ON "FeedEvent"("projectId", "stageId", "createdAt");
