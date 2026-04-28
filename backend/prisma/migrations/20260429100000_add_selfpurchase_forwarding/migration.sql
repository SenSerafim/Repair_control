-- AlterEnum: новый kind для feed-события forwarding
ALTER TYPE "FeedEventKind" ADD VALUE 'selfpurchase_forwarded';

-- AlterTable: 3-tier forwarding (master→foreman→customer)
ALTER TABLE "SelfPurchase" ADD COLUMN "forwardedFromId" TEXT;

-- CreateIndex
CREATE INDEX "SelfPurchase_forwardedFromId_idx" ON "SelfPurchase"("forwardedFromId");

-- AddForeignKey
ALTER TABLE "SelfPurchase" ADD CONSTRAINT "SelfPurchase_forwardedFromId_fkey" FOREIGN KEY ("forwardedFromId") REFERENCES "SelfPurchase"("id") ON DELETE SET NULL ON UPDATE CASCADE;
