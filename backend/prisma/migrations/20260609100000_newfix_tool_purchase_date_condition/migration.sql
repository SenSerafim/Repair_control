-- NEWFIX §6.1 — Tool condition + purchase date.
-- Владелец инструмента указывает дату покупки и текущее состояние
-- (для предупреждения о гарантии и оценки износа).

CREATE TYPE "ToolCondition" AS ENUM ('new_tool', 'good', 'worn', 'broken');

ALTER TABLE "ToolItem"
  ADD COLUMN "purchaseDate" TIMESTAMP(3),
  ADD COLUMN "condition" "ToolCondition";
