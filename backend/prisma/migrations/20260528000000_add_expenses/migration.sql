-- E2 — Бюджет проекта rewrite + Expense
-- ТЗ NEWFIX §5: «расход» как отдельная сущность, не привязанная к получателю,
-- категория + опциональное фото чека + автопривязка к этапу.

-- 1) enum категории расходов
CREATE TYPE "ExpenseCategory" AS ENUM ('materials', 'transport', 'rental', 'services', 'other');

-- 2) таблица Expense
CREATE TABLE "Expense" (
  "id"          TEXT              NOT NULL,
  "projectId"   TEXT              NOT NULL,
  "stageId"     TEXT,
  "createdById" TEXT              NOT NULL,
  "category"    "ExpenseCategory" NOT NULL DEFAULT 'other',
  "name"        TEXT              NOT NULL,
  "amount"      BIGINT            NOT NULL,
  "comment"     TEXT,
  "photoKey"    TEXT,
  "createdAt"   TIMESTAMP(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"   TIMESTAMP(3)      NOT NULL,
  CONSTRAINT "Expense_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "Expense_projectId_createdAt_idx" ON "Expense" ("projectId", "createdAt");
CREATE INDEX "Expense_stageId_idx" ON "Expense" ("stageId");
CREATE INDEX "Expense_category_idx" ON "Expense" ("category");

ALTER TABLE "Expense"
  ADD CONSTRAINT "Expense_projectId_fkey"
    FOREIGN KEY ("projectId") REFERENCES "Project" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Expense"
  ADD CONSTRAINT "Expense_stageId_fkey"
    FOREIGN KEY ("stageId") REFERENCES "Stage" ("id") ON DELETE SET NULL ON UPDATE CASCADE;
