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

// Partial-record: устаревшие kind'ы (например, material_disputed) остаются в
// Prisma-enum для совместимости с историческими данными, но шаблона для них
// нет — приложение их больше не публикует.
export const NOTIFICATION_TEMPLATES: Partial<Record<NotificationKind, NotificationTemplate>> = {
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
  selfpurchase_created: t(
    'selfpurchase_created',
    'critical',
    'Самозакуп на подтверждение',
    (p) => `${p.amountRub ?? ''} ₽ — требуется подтверждение`,
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
  // ---------- 2026-05-04: новые kind (П1.11, П2.4-2.6, П2.15, П2.18) ----------
  stage_foreman_assigned: t(
    'stage_foreman_assigned',
    'high',
    'Вы назначены бригадиром',
    (p) => `Этап «${p.stageTitle ?? ''}» — назначен бригадиром`,
  ),
  stage_master_assigned: t(
    'stage_master_assigned',
    'high',
    'Вы назначены мастером',
    (p) => `Этап «${p.stageTitle ?? ''}» — назначен мастером`,
  ),
  stage_create_requested: t(
    'stage_create_requested',
    'critical',
    'Этап ожидает согласования',
    (p) => `Бригадир добавил этап «${p.title ?? ''}» — требуется согласование`,
  ),
  material_purchase_requested: t(
    'material_purchase_requested',
    'critical',
    'Заявка на покупку материалов',
    (p) => `Бригадир запрашивает покупку на ${p.amountRub ?? ''} ₽`,
  ),
  budget_changed: t(
    'budget_changed',
    'high',
    'Бюджет проекта изменён',
    (p) => `Новый общий бюджет: ${p.newTotalRub ?? ''} ₽`,
  ),
  tool_custody_changed: t(
    'tool_custody_changed',
    'high',
    'Инструмент сменил держателя',
    (p) => `${p.holderName ?? 'Участник'} забрал «${p.toolName ?? ''}»`,
  ),
};

/** Критичные типы — пользователь не может отключить. */
export function isCritical(kind: NotificationKind): boolean {
  return NOTIFICATION_TEMPLATES[kind]?.priority === 'critical';
}
