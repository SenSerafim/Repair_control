-- E12 — расширение Tool по NEWFIX-2 §7.1
-- Артикул, статус (4 значения), местоположение (свободный текст склад/гараж),
-- assignedEmployeeId (на сотрудника). projectId уже существует — переиспользуем
-- для статуса 'on_project'.

-- 1) enum статуса инструмента
CREATE TYPE "ToolStatus" AS ENUM ('in_storage', 'on_project', 'with_employee');

-- 2) поля карточки
ALTER TABLE "ToolItem"
  ADD COLUMN "article"            TEXT,
  ADD COLUMN "status"             "ToolStatus" NOT NULL DEFAULT 'in_storage',
  ADD COLUMN "storageLocation"    TEXT,
  ADD COLUMN "assignedEmployeeId" TEXT;

-- 3) индексы для фильтра/поиска по статусу и связке с сотрудником
CREATE INDEX "ToolItem_status_idx" ON "ToolItem" ("status");
CREATE INDEX "ToolItem_assignedEmployeeId_idx" ON "ToolItem" ("assignedEmployeeId");

-- 4) бекфил: для уже существующих project-tools — статус on_project,
-- для прочих — оставляем дефолт in_storage
UPDATE "ToolItem" SET "status" = 'on_project' WHERE "projectId" IS NOT NULL;

-- 5) FK на User для assignedEmployeeId (nullable, SET NULL при удалении user-а)
ALTER TABLE "ToolItem"
  ADD CONSTRAINT "ToolItem_assignedEmployeeId_fkey"
    FOREIGN KEY ("assignedEmployeeId") REFERENCES "User" ("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
