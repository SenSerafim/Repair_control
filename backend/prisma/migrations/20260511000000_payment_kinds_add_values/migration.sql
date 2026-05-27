-- 2026-05 рефактор RBAC + Payment модели.
-- Расширение enum PaymentKind тремя значениями из ТЗ §8:
--   final         — окончательный расчёт customer → foreman
--   selfpurchase  — подтверждённый самозакуп (зеркало SelfPurchase в Payment-ledger)
--   extra_work    — одобренная доп.работа (зеркало Approval(extra_work))
--
-- ALTER TYPE ENUM ADD VALUE выполняется в собственной транзакции;
-- использовать новые значения в DML можно только в последующих миграциях
-- (см. 20260511000001_unified_payment_columns_and_backfill).

ALTER TYPE "PaymentKind" ADD VALUE IF NOT EXISTS 'final';
ALTER TYPE "PaymentKind" ADD VALUE IF NOT EXISTS 'selfpurchase';
ALTER TYPE "PaymentKind" ADD VALUE IF NOT EXISTS 'extra_work';
