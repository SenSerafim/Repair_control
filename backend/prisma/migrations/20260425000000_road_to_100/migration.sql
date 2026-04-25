-- ROAD TO 100 — Этап 1
-- 1.1 Step.methodologyArticleId
-- 1.2 PaymentDispute.photoKeys[]
-- 1.4 Subscription / FeatureFlag stubs (ТЗ §5.7)

-- AlterTable: Step.methodologyArticleId
ALTER TABLE "Step" ADD COLUMN "methodologyArticleId" TEXT;

-- AddForeignKey
ALTER TABLE "Step"
  ADD CONSTRAINT "Step_methodologyArticleId_fkey"
  FOREIGN KEY ("methodologyArticleId") REFERENCES "MethodologyArticle"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;

-- CreateIndex
CREATE INDEX "Step_methodologyArticleId_idx" ON "Step"("methodologyArticleId");

-- AlterTable: PaymentDispute.photoKeys[]
ALTER TABLE "PaymentDispute" ADD COLUMN "photoKeys" TEXT[] DEFAULT ARRAY[]::TEXT[];

-- CreateTable: Subscription
CREATE TABLE "Subscription" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "plan" TEXT NOT NULL DEFAULT 'free',
    "validTo" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Subscription_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Subscription_userId_idx" ON "Subscription"("userId");
CREATE INDEX "Subscription_plan_idx" ON "Subscription"("plan");

-- AddForeignKey
ALTER TABLE "Subscription"
  ADD CONSTRAINT "Subscription_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

-- CreateTable: FeatureFlag
CREATE TABLE "FeatureFlag" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "plan" TEXT NOT NULL DEFAULT 'free',
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "FeatureFlag_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "FeatureFlag_key_key" ON "FeatureFlag"("key");
CREATE INDEX "FeatureFlag_plan_enabled_idx" ON "FeatureFlag"("plan", "enabled");
