/// RU-локализация title/body для NotificationKind (P1.2).
///
/// Источник: backend/prisma/schema.prisma `enum NotificationKind` + ТЗ §15.2.
/// Используется в `notifications_screen.dart` при рендере карточки уведомления.
/// Если ключа нет в карте — UI fallback на raw notification.title/body
/// (FCM payload бэкенда).
class NotifTemplate {
  const NotifTemplate({required this.title, required this.body});
  final String title;

  /// {param} — плейсхолдеры, заполняемые из notification.payload.
  final String body;
}

/// Карта kind (строка из FCM data) → шаблон title+body.
const Map<String, NotifTemplate> kNotifRu = {
  // --- CRITICAL ---
  'approval_requested': NotifTemplate(
    title: 'Новое согласование',
    body: 'Требуется ваше решение по «{stageName}»',
  ),
  'approval_approved': NotifTemplate(
    title: 'Согласование одобрено',
    body: 'Заказчик одобрил «{approvalTitle}»',
  ),
  'approval_rejected': NotifTemplate(
    title: 'Согласование отклонено',
    body: 'Заказчик отклонил «{approvalTitle}». Причина: {reason}',
  ),
  'payment_created': NotifTemplate(
    title: 'Новая оплата',
    body: 'Создан платёж на {amount} ₽ — ожидает подтверждения',
  ),
  'payment_confirmed': NotifTemplate(
    title: 'Оплата подтверждена',
    body: 'Получатель подтвердил получение {amount} ₽',
  ),
  'payment_disputed': NotifTemplate(
    title: 'Открыт спор по оплате',
    body: '{actorName} открыл диспут по платежу {amount} ₽',
  ),
  'payment_resolved': NotifTemplate(
    title: 'Спор по оплате закрыт',
    body: 'Решение принято — {resolution}',
  ),
  'stage_rejected_by_customer': NotifTemplate(
    title: 'Этап не принят',
    body: 'Этап «{stageName}» отклонён. Замечания: {reason}',
  ),
  'stage_overdue': NotifTemplate(
    title: 'Просрочен этап',
    body: 'Этап «{stageName}» прошёл срок сдачи',
  ),
  'stage_deadline_exceeds_project': NotifTemplate(
    title: 'Срок этапа выходит за проект',
    body: 'Этап «{stageName}» — дедлайн позже окончания проекта',
  ),
  'material_request_created': NotifTemplate(
    title: 'Запрошен материал',
    body: 'Бригада запросила {materialName} — требуется одобрение',
  ),
  'material_delivered': NotifTemplate(
    title: 'Материал доставлен',
    body: 'Получено: {materialName}',
  ),
  'material_disputed': NotifTemplate(
    title: 'Спор по материалу',
    body: 'Бригада оспаривает доставку: {materialName}',
  ),
  'selfpurchase_created': NotifTemplate(
    title: 'Заявка на самозакуп',
    body: '{actorName} запросил компенсацию {amount} ₽',
  ),
  'tool_issued': NotifTemplate(
    title: 'Выдан инструмент',
    body: 'Вам выдан {toolName}, {qty} шт. Подтвердите получение.',
  ),
  'export_completed': NotifTemplate(
    title: 'Экспорт готов',
    body: 'Файл «{exportName}» готов к скачиванию',
  ),
  'export_failed': NotifTemplate(
    title: 'Ошибка экспорта',
    body: 'Не удалось сформировать файл — попробуйте ещё раз',
  ),
  // --- HIGH ---
  'chat_message_new': NotifTemplate(
    title: '{senderName} в «{chatName}»',
    body: '{messagePreview}',
  ),
  'step_completed': NotifTemplate(
    title: 'Шаг выполнен',
    body: 'Мастер закрыл шаг «{stepName}»',
  ),
  'stage_completed': NotifTemplate(
    title: 'Этап завершён',
    body: 'Этап «{stageName}» отправлен на приёмку',
  ),
  'stage_paused': NotifTemplate(
    title: 'Этап на паузе',
    body: 'Этап «{stageName}» поставлен на паузу: {reason}',
  ),
  'note_created_for_me': NotifTemplate(
    title: 'Новая заметка',
    body: '{actorName} оставил заметку: «{notePreview}»',
  ),
  'question_asked': NotifTemplate(
    title: 'Новый вопрос',
    body: '{actorName} задал вопрос по «{stepName}»',
  ),
  // --- NORMAL / system ---
  'project_archived': NotifTemplate(
    title: 'Проект в архиве',
    body: 'Проект «{projectName}» переведён в архив',
  ),
  'membership_added': NotifTemplate(
    title: 'Вас добавили в проект',
    body: 'Вы участник «{projectName}» в роли {role}',
  ),
};

final RegExp _placeholder = RegExp(r'\{(\w+)\}');

String _interpolate(String template, Map<String, dynamic> payload) {
  return template.replaceAllMapped(_placeholder, (m) {
    final key = m.group(1)!;
    final v = payload[key];
    return v?.toString() ?? '';
  });
}

/// Возвращает RU-title для kind, заполняя плейсхолдеры из payload.
/// При отсутствии шаблона — возвращает [fallback].
String renderNotifTitle(
  String kind,
  Map<String, dynamic> payload, {
  String? fallback,
}) {
  final tpl = kNotifRu[kind];
  if (tpl == null) return fallback ?? '';
  return _interpolate(tpl.title, payload);
}

/// Возвращает RU-body для kind, заполняя плейсхолдеры из payload.
/// При отсутствии шаблона — возвращает [fallback].
String renderNotifBody(
  String kind,
  Map<String, dynamic> payload, {
  String? fallback,
}) {
  final tpl = kNotifRu[kind];
  if (tpl == null) return fallback ?? '';
  return _interpolate(tpl.body, payload);
}

/// Критичные уведомления (показ lock-иконки + tooltip в notification_settings_screen).
const Set<String> kCriticalNotifKinds = {
  'approval_requested',
  'approval_approved',
  'approval_rejected',
  'payment_created',
  'payment_confirmed',
  'payment_disputed',
  'payment_resolved',
  'stage_rejected_by_customer',
  'stage_overdue',
  'stage_deadline_exceeds_project',
  'material_request_created',
  'material_delivered',
  'material_disputed',
  'selfpurchase_created',
  'tool_issued',
  'export_completed',
  'export_failed',
};
