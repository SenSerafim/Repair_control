-- Documents: пользовательские поля "описание" и "дата документа"
-- (отличается от createdAt — это дата самого документа, не загрузки).
ALTER TABLE "Document" ADD COLUMN "description"  TEXT;
ALTER TABLE "Document" ADD COLUMN "documentDate" TIMESTAMP(3);
