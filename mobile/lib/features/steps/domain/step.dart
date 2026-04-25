import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/widgets/status_pill.dart';

part 'step.freezed.dart';

/// Тип шага — regular (обычный) или extra (доп.работа, требует
/// согласования заказчика с ценой).
enum StepType {
  regular,
  extra;

  static StepType fromString(String? raw) =>
      raw == 'extra' ? StepType.extra : StepType.regular;
}

/// Статус шага — соответствует backend enum `StepStatus`.
enum StepStatus {
  pending,
  inProgress,
  done,
  pendingApproval,
  rejected;

  String get apiValue => switch (this) {
        StepStatus.pending => 'pending',
        StepStatus.inProgress => 'in_progress',
        StepStatus.done => 'done',
        StepStatus.pendingApproval => 'pending_approval',
        StepStatus.rejected => 'rejected',
      };

  static StepStatus fromString(String? raw) {
    switch (raw) {
      case 'in_progress':
        return StepStatus.inProgress;
      case 'done':
        return StepStatus.done;
      case 'pending_approval':
        return StepStatus.pendingApproval;
      case 'rejected':
        return StepStatus.rejected;
      case 'pending':
      default:
        return StepStatus.pending;
    }
  }

  String get displayName => switch (this) {
        StepStatus.pending => 'Ожидает',
        StepStatus.inProgress => 'В работе',
        StepStatus.done => 'Выполнен',
        StepStatus.pendingApproval => 'На согласовании',
        StepStatus.rejected => 'Отклонён',
      };

  Semaphore get semaphore => switch (this) {
        StepStatus.pending => Semaphore.plan,
        StepStatus.inProgress => Semaphore.green,
        StepStatus.done => Semaphore.green,
        StepStatus.pendingApproval => Semaphore.blue,
        StepStatus.rejected => Semaphore.red,
      };
}

@freezed
class Step with _$Step {
  const factory Step({
    required String id,
    required String stageId,
    required String title,
    required int orderIndex,
    required StepType type,
    required StepStatus status,
    int? price,
    String? description,
    required String authorId,
    @Default(<String>[]) List<String> assigneeIds,
    DateTime? doneAt,
    String? doneById,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(0) int substepsCount,
    @Default(0) int substepsDone,
    @Default(0) int photosCount,

    /// Опциональная ссылка на статью методички. Если бэк прислал id —
    /// `StepDetailScreen` показывает кнопку «Открыть методичку»
    /// (deep-link на `/methodology/articles/:id`).
    String? methodologyArticleId,
  }) = _Step;

  static Step parse(Map<String, dynamic> json) => Step(
        id: json['id'] as String,
        stageId: json['stageId'] as String,
        title: json['title'] as String,
        orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
        type: StepType.fromString(json['type'] as String?),
        status: StepStatus.fromString(json['status'] as String?),
        price: (json['price'] as num?)?.toInt(),
        description: json['description'] as String?,
        authorId: json['authorId'] as String? ?? '',
        assigneeIds: (json['assigneeIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        doneAt: _date(json['doneAt']),
        doneById: json['doneById'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        substepsCount:
            (json['substepsCount'] as num?)?.toInt() ??
                (json['substeps'] as List<dynamic>?)?.length ??
                0,
        substepsDone: (json['substepsDone'] as num?)?.toInt() ??
            (json['substeps'] as List<dynamic>? ?? const [])
                .where((s) => (s as Map)['isDone'] == true)
                .length,
        photosCount: (json['photosCount'] as num?)?.toInt() ??
            (json['photos'] as List<dynamic>?)?.length ??
            0,
        methodologyArticleId: json['methodologyArticleId'] as String?,
      );
}

DateTime? _date(Object? raw) =>
    raw is String ? DateTime.tryParse(raw) : null;

extension StepX on Step {
  bool get isDone => status == StepStatus.done;
  bool get isExtra => type == StepType.extra;
}
