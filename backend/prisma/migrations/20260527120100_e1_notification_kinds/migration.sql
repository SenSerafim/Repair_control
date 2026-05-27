-- E1a — расширение NotificationKind для трёх новых событий заявок.
-- ТЗ NEWFIX §5.4 + §5.7.

ALTER TYPE "NotificationKind" ADD VALUE IF NOT EXISTS 'material_request_accepted_partial';
ALTER TYPE "NotificationKind" ADD VALUE IF NOT EXISTS 'material_request_accepted_full';
ALTER TYPE "NotificationKind" ADD VALUE IF NOT EXISTS 'material_request_overdue';
