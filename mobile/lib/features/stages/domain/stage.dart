import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/widgets/status_pill.dart';

part 'stage.freezed.dart';

/// Статус этапа — соответствует backend enum `StageStatus`.
/// 7 состояний из ТЗ §2.4 (late-start — computed на клиенте).
enum StageStatus {
  pending,
  active,
  paused,
  review,
  done,
  rejected;

  static StageStatus fromString(String? raw) {
    if (raw == null) return StageStatus.pending;
    for (final s in values) {
      if (s.name.toLowerCase() == raw.toLowerCase()) return s;
    }
    return StageStatus.pending;
  }

  String get displayName => switch (this) {
        StageStatus.pending => 'Ожидает',
        StageStatus.active => 'В работе',
        StageStatus.paused => 'На паузе',
        StageStatus.review => 'На приёмке',
        StageStatus.done => 'Завершён',
        StageStatus.rejected => 'Отклонён',
      };

  Semaphore get semaphore => switch (this) {
        StageStatus.pending => Semaphore.plan,
        StageStatus.active => Semaphore.green,
        StageStatus.paused => Semaphore.yellow,
        StageStatus.review => Semaphore.blue,
        StageStatus.done => Semaphore.green,
        StageStatus.rejected => Semaphore.red,
      };
}

@freezed
class Stage with _$Stage {
  const factory Stage({
    required String id,
    required String projectId,
    required String title,
    required int orderIndex,
    required StageStatus status,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    DateTime? originalEnd,
    required int pauseDurationMs,
    required int workBudget,
    required int materialsBudget,
    @Default(<String>[]) List<String> foremanIds,
    required int progressCache,
    required bool planApproved,
    DateTime? startedAt,
    DateTime? sentToReviewAt,
    DateTime? doneAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Stage;

  static Stage parse(Map<String, dynamic> json) => Stage(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        title: json['title'] as String,
        orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
        status: StageStatus.fromString(json['status'] as String?),
        plannedStart: _date(json['plannedStart']),
        plannedEnd: _date(json['plannedEnd']),
        originalEnd: _date(json['originalEnd']),
        pauseDurationMs: (json['pauseDurationMs'] as num?)?.toInt() ?? 0,
        workBudget: (json['workBudget'] as num?)?.toInt() ?? 0,
        materialsBudget: (json['materialsBudget'] as num?)?.toInt() ?? 0,
        foremanIds: (json['foremanIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        progressCache: (json['progressCache'] as num?)?.toInt() ?? 0,
        planApproved: json['planApproved'] as bool? ?? false,
        startedAt: _date(json['startedAt']),
        sentToReviewAt: _date(json['sentToReviewAt']),
        doneAt: _date(json['doneAt']),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

DateTime? _date(Object? raw) {
  if (raw == null) return null;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

extension StageX on Stage {
  /// Этап помечен как late-start — дата планового старта прошла,
  /// но `startedAt` не выставлен. ТЗ §2.4.
  bool isLateStart(DateTime now) =>
      status == StageStatus.pending &&
      plannedStart != null &&
      plannedStart!.isBefore(now) &&
      startedAt == null;
}
