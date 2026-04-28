-- Soft-delete account support (Cluster A: «Удалить аккаунт»)
ALTER TABLE "User" ADD COLUMN "deletedAt" TIMESTAMP(3);
CREATE INDEX "User_deletedAt_idx" ON "User"("deletedAt");
