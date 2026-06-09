-- NEWFIX §4.1 — Reclamation flow.
-- Заказчик и представитель могут отправить шаг на доработку: новый
-- ApprovalScope='defect' с обязательным фото-доказательством (через
-- существующую ApprovalAttachment) и payload.description.

ALTER TYPE "ApprovalScope" ADD VALUE 'defect';
