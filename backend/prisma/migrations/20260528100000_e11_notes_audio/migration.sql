-- E11 — заметки на проекте с аудио (NEWFIX-2 §11)
-- Вариант A (MVP): только аудио, без транскрипции. Поля transcript* остаются
-- в схеме как задел для варианта B (фоновый STT через BullMQ).

-- 1) enums
CREATE TYPE "NoteKind" AS ENUM ('text', 'audio');
CREATE TYPE "TranscriptStatus" AS ENUM ('pending', 'done', 'failed');

-- 2) колонки Note
ALTER TABLE "Note"
  ADD COLUMN "kind"               "NoteKind"         NOT NULL DEFAULT 'text',
  ADD COLUMN "audioKey"           TEXT,
  ADD COLUMN "audioMimeType"      TEXT,
  ADD COLUMN "audioDurationMs"    INTEGER,
  ADD COLUMN "transcript"         TEXT,
  ADD COLUMN "transcriptStatus"   "TranscriptStatus",
  ADD COLUMN "transcriptProvider" TEXT;

-- 3) text становится nullable: у аудио-заметки текста может не быть
ALTER TABLE "Note" ALTER COLUMN "text" DROP NOT NULL;

CREATE INDEX "Note_kind_idx" ON "Note" ("kind");
