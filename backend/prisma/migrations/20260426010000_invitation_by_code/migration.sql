-- ProjectInvitation: расширяем под invite-by-code (P2).
-- 1. phone становится опциональным (default '') — для P2 кодов телефон не нужен.
ALTER TABLE "ProjectInvitation" ALTER COLUMN "phone" SET DEFAULT '';

-- 2. Делегированные права при акцепте (для representative).
ALTER TABLE "ProjectInvitation" ADD COLUMN "permissions" JSONB;

-- 3. Список этапов, на которые добавляют (опционально).
ALTER TABLE "ProjectInvitation" ADD COLUMN "stageIds" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];

-- 4. Запоминаем кто и когда принял.
ALTER TABLE "ProjectInvitation" ADD COLUMN "acceptedBy" TEXT;
ALTER TABLE "ProjectInvitation" ADD COLUMN "acceptedAt" TIMESTAMP(3);

-- 5. Индекс по (token, status) — для быстрого поиска активного pending кода.
CREATE INDEX "ProjectInvitation_token_status_idx" ON "ProjectInvitation"("token", "status");
