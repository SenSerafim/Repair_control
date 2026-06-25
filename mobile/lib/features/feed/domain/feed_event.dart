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
    payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// Технические FeedEventKind, которые UI не должен показывать в ленте проекта.
/// Бэк их пишет в feed для админки/аудита, но в потребительском списке это
/// шум: создание чата, изменение видимости, ротация участников чата,
/// каждое отправленное сообщение и т.п.
///
/// QA-баги #9 и #10: ранее в ленте мелькали `chat_created`,
/// `chat_message_sent` как сырые технические идентификаторы (FeedEventX
/// .summary fallback'ом возвращает kind, если в `labels` нет ключа), что
/// QA воспринял как «поехала вёрстка» — на фоне нормальных «Новый этап /
/// Создан проект» это выглядит сломанным. Решение: вообще не показывать
/// эти kind'ы в потребительской ленте.
const _hiddenFeedKinds = <String>{
  'chat_created',
  'chat_message_sent',
  'chat_message_edited',
  'chat_message_deleted',
  'chat_participant_added',
  'chat_participant_removed',
  'chat_visibility_toggled',
  'message_sent',
  'message_edited',
  'message_deleted',
};

extension FeedEventX on FeedEvent {
  FeedCategory get category => FeedCategory.fromKind(kind);

  String? _payloadString(String key) {
    final value = payload[key];
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Должно ли событие отображаться в потребительской ленте проекта.
  /// `false` — событие записано в БД (для аудита/админки), но UI его прячет.
  bool get isUiVisible => !_hiddenFeedKinds.contains(kind);

  /// Тон цветной точки для feed-row (`Кластер F` — `f-feed`).
  AppFeedDotTone get dotTone {
    if (kind == 'approval_rejected' ||
        kind == 'stage_rejected_by_customer' ||
        kind.endsWith('_failed')) {
      return AppFeedDotTone.danger;
    }
    if (kind == 'approval_approved' ||
        kind == 'plan_approved' ||
        kind == 'stage_accepted' ||
        kind == 'step_completed' ||
        kind == 'stage_completed' ||
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
      'material_delivered',
      'material_partially_bought',
      'deadline_changed',
      'export_ready',
    };
    return immutable.contains(kind);
  }

  /// Человекочитаемый заголовок события.
  String get summary {
    final title = _payloadString('title') ?? _payloadString('stageTitle');
    final quotedTitle = title == null ? '' : ' «$title»';
    if (kind == 'stage_created') return 'Добавлен этап$quotedTitle';
    if (kind == 'step_created') return 'Добавлен шаг$quotedTitle';
    if (kind == 'material_request_sent') {
      return title == null
          ? 'Создана заявка на материалы'
          : 'Создана заявка «$title»';
    }
    if (kind == 'budget_updated') {
      return switch (_payloadString('reason')) {
        'material_approved' => 'Бюджет пересчитан по заявке',
        'payment_created' => 'Бюджет пересчитан после выплаты',
        _ => 'Бюджет пересчитан',
      };
    }

    // Простой маппинг для самых частых событий.
    const labels = <String, String>{
      'project_created': 'Создан проект',
      'project_archived': 'Проект в архиве',
      'project_restored': 'Проект восстановлен',
      'stage_started': 'Этап запущен',
      'stage_paused': 'Этап на паузе',
      'stage_resumed': 'Этап возобновлён',
      'stage_sent_to_review': 'Этап на приёмку',
      'stage_accepted': 'Этап принят',
      'stage_rejected_by_customer': 'Этап отклонён',
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
      'payment_created': 'Добавлена выплата',
      'document_uploaded': 'Загружен документ',
      'export_ready': 'Экспорт готов',
      'membership_added': 'Добавлен участник',
      'extra_work_requested': 'Запрошены доп.работы',
    };
    final hit = labels[kind];
    if (hit != null) return hit;
    // Defensive fallback: на новый kind с бэка, для которого ещё нет
    // явного перевода, не показываем сырой technical id (это и было
    // частью QA-бага #9 — `chat_message_sent` светился в ленте). Берём
    // префикс категории как читаемый заголовок: «Этап», «Шаг»,
    // «Финансы» и т.д.
    return category.displayName;
  }

  /// Человекочитаемое пояснение к technical `payload.reason`.
  ///
  /// В UI нельзя показывать сырой enum (`material_approved`), это служебный
  /// контракт между доменами. Здесь переводим известные причины, неизвестные
  /// скрываем, чтобы новая backend-причина не протекла в интерфейс.
  String? get reasonText {
    return switch (_payloadString('reason')) {
      'material_approved' => 'Заявка на материалы согласована',
      'payment_created' => 'Создана выплата',
      'materials' => 'Ожидание материалов',
      'approval' => 'Ожидание согласования',
      'force_majeure' => 'Форс-мажор',
      'other' => 'Другая причина',
      _ => null,
    };
  }
}
