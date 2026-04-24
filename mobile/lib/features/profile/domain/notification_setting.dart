import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_setting.freezed.dart';

/// Соответствует backend enum `NotificationPriority`.
enum NotificationPriority {
  critical,
  high,
  normal,
  low;

  static NotificationPriority fromString(String? raw) {
    if (raw == null) return NotificationPriority.normal;
    for (final p in values) {
      if (p.name.toLowerCase() == raw.toLowerCase()) return p;
    }
    return NotificationPriority.normal;
  }

  String get displayName => switch (this) {
        NotificationPriority.critical => 'Критичные',
        NotificationPriority.high => 'Важные',
        NotificationPriority.normal => 'Обычные',
        NotificationPriority.low => 'Информационные',
      };
}

/// Настройка уведомления: ответ GET /api/me/notification-settings.
@freezed
class NotificationSetting with _$NotificationSetting {
  const factory NotificationSetting({
    required String kind,
    required bool pushEnabled,
    required NotificationPriority priority,
    required bool critical,
  }) = _NotificationSetting;

  static NotificationSetting parse(Map<String, dynamic> json) =>
      NotificationSetting(
        kind: json['kind'] as String,
        pushEnabled: json['pushEnabled'] as bool? ?? true,
        priority: NotificationPriority.fromString(json['priority'] as String?),
        critical: json['critical'] as bool? ?? false,
      );
}

/// Человекочитаемое имя для backend enum `NotificationKind`.
/// Точный список NotificationKind'ов живёт в backend Prisma schema —
/// здесь перечислены основные, неизвестные кинды показываются по ключу.
const notificationKindLabels = <String, String>{
  'stage_assigned': 'Новый этап',
  'stage_paused': 'Этап на паузе',
  'stage_resumed': 'Этап возобновлён',
  'stage_rejected': 'Этап отклонён',
  'stage_accepted': 'Этап принят',
  'stage_overdue': 'Этап просрочен',
  'step_completed': 'Шаг выполнен',
  'approval_requested': 'Запрос согласования',
  'approval_approved': 'Согласовано',
  'approval_rejected': 'Отклонено',
  'approval_extra_work': 'Доп.работа',
  'deadline_change_requested': 'Изменение дедлайна',
  'payment_created': 'Новая выплата',
  'payment_confirmed': 'Выплата подтверждена',
  'payment_disputed': 'Спор по выплате',
  'payment_resolved': 'Спор решён',
  'material_request_sent': 'Заявка на материалы',
  'material_confirmed': 'Материалы подтверждены',
  'chat_message': 'Сообщения в чате',
  'chat_mention': 'Упоминание в чате',
  'document_uploaded': 'Документ загружен',
  'export_ready': 'Экспорт готов',
  'legal_version_updated': 'Обновление юр-документов',
};
