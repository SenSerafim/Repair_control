import 'package:flutter/material.dart';

/// Причина паузы этапа — соответствует backend enum `PauseReason`.
enum PauseReason {
  materials,
  approval,
  forceMajeure,
  other;

  /// API-значение для отправки на бекенд.
  String get apiValue => switch (this) {
        PauseReason.materials => 'materials',
        PauseReason.approval => 'approval',
        PauseReason.forceMajeure => 'force_majeure',
        PauseReason.other => 'other',
      };

  String get displayName => switch (this) {
        PauseReason.materials => 'Ждём материалы',
        PauseReason.approval => 'Ждём согласование',
        PauseReason.forceMajeure => 'Форс-мажор',
        PauseReason.other => 'Другая причина',
      };

  String get hint => switch (this) {
        PauseReason.materials =>
          'Материалы не привезли или заказчик не подтвердил.',
        PauseReason.approval =>
          'Ждём ответ заказчика по согласованию.',
        PauseReason.forceMajeure =>
          'Обстоятельства вне зоны контроля (погода, доступ, …).',
        PauseReason.other => 'Укажите подробности в комментарии.',
      };

  IconData get icon => switch (this) {
        PauseReason.materials => Icons.inventory_2_outlined,
        PauseReason.approval => Icons.pending_actions_outlined,
        PauseReason.forceMajeure => Icons.warning_amber_rounded,
        PauseReason.other => Icons.edit_note_outlined,
      };

  static PauseReason fromApiValue(String? raw) {
    switch (raw) {
      case 'materials':
        return PauseReason.materials;
      case 'approval':
        return PauseReason.approval;
      case 'force_majeure':
        return PauseReason.forceMajeure;
      case 'other':
      default:
        return PauseReason.other;
    }
  }
}
