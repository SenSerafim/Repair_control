import { NotificationKind, NotificationPriority } from '@prisma/client';

export interface NotificationTemplate {
  kind: NotificationKind;
  priority: NotificationPriority;
  render: (payload: Record<string, unknown>) => { title: string; body: string };
}

const t = (
  kind: NotificationKind,
  priority: NotificationPriority,
  title: string,
  bodyFn: (p: Record<string, unknown>) => string,
): NotificationTemplate => ({
  kind,
  priority,
  render: (payload) => ({ title, body: bodyFn(payload) }),
});

export const NOTIFICATION_TEMPLATES: Record<NotificationKind, NotificationTemplate> = {
  // ---------- CRITICAL ----------
  approval_requested: t(
    'approval_requested',
    'critical',
    'Требуется согласование',
    (p) => `${p.scopeRu ?? 'Запрос'} ожидает вашего решения`,
  ),
  approval_approved: t(
    'approval_approved',
    'critical',
    'Согласование одобрено',
    (p) => `Запрос ${p.scopeRu ?? ''} одобрен`,
  ),
  approval_rejected: t('approval_rejected', 'critical', 'Согласование отклонено', (p) =>
    p.comment ? `Отклонено: ${p.comment}` : 'Запрос отклонён',
  ),
  payment_created: t(
    'payment_created',
    'critical',
    'Новая выплата',
    (p) => `Поступил платёж ${p.amountRub ?? ''} ₽`,
  ),
  payment_confirmed: t(
    'payment_confirmed',
    'critical',
    'Выплата подтверждена',
    (p) => `Платёж ${p.amountRub ?? ''} ₽ подтверждён`,
  ),
  payment_disputed: t(
    'payment_disputed',
    'critical',
    'Спор по выплате',
    (p) => `Открыт спор по платежу ${p.amountRub ?? ''} ₽`,
  ),
  payment_resolved: t(
    'payment_resolved',
    'critical',
    'Спор по выплате решён',
    () => 'Итоговая сумма зафиксирована',
  ),
  stage_rejected_by_customer: t(
    'stage_rejected_by_customer',
    'critical',
    'Этап возвращён на доработку',
    (p) => String(p.comment ?? 'Требуется доработка'),
  ),
  stage_overdue: t(
    'stage_overdue',
    'critical',
    'Этап просрочен',
    (p) => `Этап «${p.stageTitle ?? ''}» просрочен`,
  ),
  stage_deadline_exceeds_project: t(
    'stage_deadline_exceeds_project',
    'critical',
    'Дедлайн этапа вне проекта',
    () => 'Пересчёт дедлайнов вывел этап за рамки проекта',
  ),
  material_request_created: t(
    'material_request_created',
    'critical',
    'Новая заявка на материалы',
    (p) => String(p.title ?? 'Заявка создана'),
  ),
  material_delivered: t('material_delivered', 'critical', 'Материалы доставлены', (p) =>
    String(p.title ?? 'Доставка подтверждена'),
  ),
  material_disputed: t('material_disputed', 'critical', 'Спор по материалам', (p) =>
    String(p.reason ?? 'Открыт спор'),
  ),
  selfpurchase_created: t(
    'selfpurchase_created',
    'critical',
    'Самозакуп на подтверждение',
    (p) => `${p.amountRub ?? ''} ₽ — требуется подтверждение`,
  ),
  tool_issued: t(
    'tool_issued',
    'critical',
    'Инструмент выдан',
    (p) => `Выдан: ${p.toolName ?? ''} (${p.qty ?? ''} шт)`,
  ),
  export_completed: t(
    'export_completed',
    'critical',
    'Отчёт готов',
    () => 'Можно скачать по ссылке в приложении',
  ),
  export_failed: t(
    'export_failed',
    'critical',
    'Отчёт не собран',
    (p) => `Ошибка экспорта: ${p.error ?? 'unknown'}`,
  ),
  // ---------- HIGH (disable-able) ----------
  chat_message_new: t('chat_message_new', 'high', 'Новое сообщение', (p) =>
    String(p.preview ?? '').slice(0, 120),
  ),
  step_completed: t('step_completed', 'high', 'Шаг завершён', (p) => String(p.stepTitle ?? '')),
  stage_completed: t('stage_completed', 'high', 'Этап завершён', (p) => String(p.stageTitle ?? '')),
  stage_paused: t('stage_paused', 'high', 'Этап на паузе', (p) =>
    String(p.reason ?? 'Пауза инициирована'),
  ),
  note_created_for_me: t('note_created_for_me', 'high', 'Вам оставили заметку', (p) =>
    String(p.preview ?? ''),
  ),
  question_asked: t('question_asked', 'high', 'Вопрос по шагу', (p) => String(p.preview ?? '')),
  // ---------- NORMAL ----------
  project_archived: t('project_archived', 'normal', 'Проект в архиве', (p) =>
    String(p.title ?? ''),
  ),
  membership_added: t('membership_added', 'normal', 'Добавлен в проект', (p) =>
    String(p.projectTitle ?? ''),
  ),
  admin_announcement: {
    kind: 'admin_announcement',
    priority: 'normal',
    render: (payload) => ({
      title: String(payload.title ?? 'Объявление'),
      body: String(payload.body ?? ''),
    }),
  },
};

/** Критичные типы — пользователь не может отключить. */
export function isCritical(kind: NotificationKind): boolean {
  return NOTIFICATION_TEMPLATES[kind].priority === 'critical';
}
