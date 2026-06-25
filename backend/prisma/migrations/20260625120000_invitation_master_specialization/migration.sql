-- Опциональная специализация мастера должна сохраняться и для приглашений:
-- незарегистрированный пользователь принимает код позже, а шильдик должен
-- попасть в Membership при join-by-code.
ALTER TABLE "ProjectInvitation" ADD COLUMN "specialization" TEXT;
