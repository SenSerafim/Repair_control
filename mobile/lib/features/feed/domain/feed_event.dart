import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/widgets/app_feed_dot.dart';

part 'feed_event.freezed.dart';

/// Категории событий ленты — группировка для фильтров.
enum FeedCategory {
  project,
  stage,
  step,
  approval,
  finance,
  materials,
  chat,
  documents,
  other;

  String get displayName => switch (this) {
        FeedCategory.project => 'Проект',
        FeedCategory.stage => 'Этапы',
        FeedCategory.step => 'Шаги',
        FeedCategory.approval => 'Согласования',
        FeedCategory.finance => 'Финансы',
        FeedCategory.materials => 'Материалы',
        FeedCategory.chat => 'Чат',
        FeedCategory.documents => 'Документы',
        FeedCategory.other => 'Прочее',
      };

  IconData get icon => switch (this) {
        FeedCategory.project => Icons.folder_outlined,
        FeedCategory.stage => Icons.dashboard_outlined,
        FeedCategory.step => Icons.checklist_outlined,
        FeedCategory.approval => Icons.rule_rounded,
        FeedCategory.finance => Icons.account_balance_wallet_outlined,
        FeedCategory.materials => Icons.inventory_2_outlined,
        FeedCategory.chat => Icons.chat_bubble_outline_rounded,
        FeedCategory.documents => Icons.insert_drive_file_outlined,
        FeedCategory.other => Icons.bolt_outlined,
      };

  /// Маппинг backend FeedEventKind → FeedCategory.
  /// Approval-события (включая stage_accepted/stage_rejected_by_customer)
  /// имеют приоритет над generic stage_* префиксом.
  static FeedCategory fromKind(String kind) {
    if (kind.startsWith('approval_') ||
        kind == 'plan_approved' ||
        kind == 'deadline_changed' ||
        kind == 'stage_accepted' ||
        kind == 'stage_rejected_by_customer') {
      return FeedCategory.approval;
    }
    if (kind.startsWith('project_')) return FeedCategory.project;
    if (kind.startsWith('stage_') || kind.startsWith('stages_')) {
      return FeedCategory.stage;
    }
    if (kind.startsWith('step_') ||
        kind.startsWith('substep_') ||
        kind.startsWith('steps_') ||
        kind.startsWith('photo_') ||
        kind.startsWith('note_') ||
        kind.startsWith('question_') ||
        kind == 'extra_work_requested' ||
        kind.startsWith('progress_')) {
      return FeedCategory.step;
    }
    if (kind.startsWith('payment_') ||
        kind == 'budget_updated' ||
        kind.startsWith('selfpurchase_')) {
      return FeedCategory.finance;
    }
    if (kind.startsWith('material_')) return FeedCategory.materials;
    if (kind.startsWith('chat_') || kind.startsWith('message_')) {
      return FeedCategory.chat;
    }
    if (kind.startsWith('document_') || kind.startsWith('export_')) {
      return FeedCategory.documents;
    }
    return FeedCategory.other;
  }
}

@freezed
class FeedEvent with _$FeedEvent {
  const factory FeedEvent({
    required String id,
    required String projectId,
    String? stageId,
    required String kind,
    required String actorId,
    @Default(<String, dynamic>{}) Map<String, dynamic> payload,
    required DateTime createdAt,
  }) = _FeedEvent;

  static FeedEvent parse(Map<String, dynamic> json) => FeedEvent(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        stageId: json['stageId'] as String?,
        kind: json['kind'] as String,
        actorId: json['actorId'] as String? ?? '',
        payload: Map<String, dynamic>.from(
          json['payload'] as Map? ?? const {},
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

extension FeedEventX on FeedEvent {
  FeedCategory get category => FeedCategory.fromKind(kind);

  /// Тон цветной точки для feed-row (`Кластер F` — `f-feed`).
  AppFeedDotTone get dotTone {
    if (kind == 'approval_rejected' ||
        kind == 'stage_rejected_by_customer' ||
        kind == 'payment_disputed' ||
        kind == 'material_disputed' ||
        kind.endsWith('_failed')) {
      return AppFeedDotTone.danger;
    }
    if (kind == 'approval_approved' ||
        kind == 'plan_approved' ||
        kind == 'stage_accepted' ||
        kind == 'step_completed' ||
        kind == 'stage_completed' ||
        kind == 'payment_confirmed' ||
        kind == 'material_delivered' ||
        kind == 'export_ready' ||
        kind.endsWith('_resolved')) {
      return AppFeedDotTone.success;
    }
    if (kind == 'stage_paused' ||
        kind == 'deadline_changed' ||
        kind == 'stage_overdue' ||
        kind == 'stage_deadline_exceeds_project') {
      return AppFeedDotTone.warning;
    }
    if (kind == 'selfpurchase_created' ||
        kind.startsWith('material_') &&
            (kind == 'material_partially_bought' ||
                kind == 'material_marked_bought')) {
      return AppFeedDotTone.info;
    }
    return AppFeedDotTone.start;
  }

  /// Неизменяемое событие — будет показан lock-badge в `f-feed`.
  /// Базовый принцип: события «факт состоялся» (одобрено, оплачено, закуплено,
  /// принято) больше не могут быть откатаны без отдельного reverse-события.
  bool get isImmutable {
    const immutable = {
      'approval_approved',
      'plan_approved',
      'stage_accepted',
      'stage_completed',
      'step_completed',
      'payment_confirmed',
      'material_delivered',
      'material_partially_bought',
      'deadline_changed',
      'export_ready',
    };
    return immutable.contains(kind);
  }

  /// Человекочитаемый заголовок события.
  String get summary {
    // Простой маппинг для самых частых событий.
    const labels = <String, String>{
      'project_created': 'Создан проект',
      'project_archived': 'Проект в архиве',
      'project_restored': 'Проект восстановлен',
      'stage_created': 'Новый этап',
      'stage_started': 'Этап запущен',
      'stage_paused': 'Этап на паузе',
      'stage_resumed': 'Этап возобновлён',
      'stage_sent_to_review': 'Этап на приёмку',
      'stage_accepted': 'Этап принят',
      'stage_rejected_by_customer': 'Этап отклонён',
      'step_created': 'Новый шаг',
      'step_completed': 'Шаг выполнен',
      'step_uncompleted': 'Шаг снят с выполнения',
      'photo_attached': 'Загружено фото',
      'note_created': 'Новая заметка',
      'question_asked': 'Новый вопрос',
      'question_answered': 'Ответ на вопрос',
      'approval_requested': 'Запрос согласования',
      'approval_approved': 'Согласовано',
      'approval_rejected': 'Отклонено',
      'plan_approved': 'План согласован',
      'deadline_changed': 'Изменён дедлайн',
      'payment_created': 'Новая выплата',
      'payment_confirmed': 'Выплата подтверждена',
      'payment_disputed': 'Спор по выплате',
      'material_request_sent': 'Заявка на материалы',
      'document_uploaded': 'Загружен документ',
      'export_ready': 'Экспорт готов',
      'membership_added': 'Новый участник',
      'extra_work_requested': 'Запрос доп.работы',
      'budget_updated': 'Обновлён бюджет',
    };
    return labels[kind] ?? kind;
  }
}
