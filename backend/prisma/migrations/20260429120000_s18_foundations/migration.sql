-- S18.1 Foundations
-- AlterEnum: добавляем admin_announcement для broadcast-кампаний.
-- Прежде BroadcastsService.send() писал NotificationLog с reused-значением 'membership_added' — это костыль.
-- Новое значение позволит корректно роутить deep-link и фильтровать audit/настройки уведомлений.
ALTER TYPE "NotificationKind" ADD VALUE 'admin_announcement';
