import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/widgets/status_pill.dart';

part 'approval.freezed.dart';

/// Тип согласования — 5 scope'ов из ТЗ §4.4.
enum ApprovalScope {
  plan,
  step,
  extraWork,
  deadlineChange,
  stageAccept;

  static ApprovalScope fromString(String? raw) {
    switch (raw) {
      case 'plan':
        return ApprovalScope.plan;
      case 'step':
        return ApprovalScope.step;
      case 'extra_work':
        return ApprovalScope.extraWork;
      case 'deadline_change':
        return ApprovalScope.deadlineChange;
      case 'stage_accept':
        return ApprovalScope.stageAccept;
      default:
        return ApprovalScope.step;
    }
  }

  String get apiValue => switch (this) {
        ApprovalScope.plan => 'plan',
        ApprovalScope.step => 'step',
        ApprovalScope.extraWork => 'extra_work',
        ApprovalScope.deadlineChange => 'deadline_change',
        ApprovalScope.stageAccept => 'stage_accept',
      };

  String get displayName => switch (this) {
        ApprovalScope.plan => 'План работ',
        ApprovalScope.step => 'Шаг',
        ApprovalScope.extraWork => 'Доп.работа',
        ApprovalScope.deadlineChange => 'Перенос дедлайна',
        ApprovalScope.stageAccept => 'Приёмка этапа',
      };

  String get shortHint => switch (this) {
        ApprovalScope.plan => 'План всех этапов',
        ApprovalScope.step => 'Отметка шага',
        ApprovalScope.extraWork => 'Работа сверх плана',
        ApprovalScope.deadlineChange => 'Перенести дату завершения',
        ApprovalScope.stageAccept => 'Завершение этапа',
      };

  IconData get icon => switch (this) {
        ApprovalScope.plan => Icons.list_alt_rounded,
        ApprovalScope.step => Icons.check_circle_outline,
        ApprovalScope.extraWork => Icons.add_circle_outline,
        ApprovalScope.deadlineChange => Icons.update_rounded,
        ApprovalScope.stageAccept => Icons.verified_outlined,
      };
}

/// Статус согласования — FSM: pending → approved|rejected|cancelled.
/// Из rejected можно resubmit → pending (attemptNumber++).
enum ApprovalStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static ApprovalStatus fromString(String? raw) {
    switch (raw) {
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      case 'cancelled':
        return ApprovalStatus.cancelled;
      case 'pending':
      default:
        return ApprovalStatus.pending;
    }
  }

  String get apiValue => switch (this) {
        ApprovalStatus.pending => 'pending',
        ApprovalStatus.approved => 'approved',
        ApprovalStatus.rejected => 'rejected',
        ApprovalStatus.cancelled => 'cancelled',
      };

  String get displayName => switch (this) {
        ApprovalStatus.pending => 'На согласовании',
        ApprovalStatus.approved => 'Одобрено',
        ApprovalStatus.rejected => 'Отклонено',
        ApprovalStatus.cancelled => 'Отменено',
      };

  Semaphore get semaphore => switch (this) {
        ApprovalStatus.pending => Semaphore.blue,
        ApprovalStatus.approved => Semaphore.green,
        ApprovalStatus.rejected => Semaphore.red,
        ApprovalStatus.cancelled => Semaphore.plan,
      };

  bool get isHistory => this != ApprovalStatus.pending;
}

@freezed
class ApprovalAttempt with _$ApprovalAttempt {
  const factory ApprovalAttempt({
    required String id,
    required String approvalId,
    required int attemptNumber,
    required String action,
    required String actorId,
    String? comment,
    required DateTime createdAt,
  }) = _ApprovalAttempt;

  static ApprovalAttempt parse(Map<String, dynamic> json) => ApprovalAttempt(
        id: json['id'] as String,
        approvalId: json['approvalId'] as String,
        attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 1,
        action: json['action'] as String? ?? 'created',
        actorId: json['actorId'] as String? ?? '',
        comment: json['comment'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

@freezed
class ApprovalAttachment with _$ApprovalAttachment {
  const factory ApprovalAttachment({
    required String id,
    required String approvalId,
    required String fileKey,
    String? thumbKey,
    required String mimeType,
    required int sizeBytes,
    String? url,
    String? thumbUrl,
  }) = _ApprovalAttachment;

  static ApprovalAttachment parse(Map<String, dynamic> json) =>
      ApprovalAttachment(
        id: json['id'] as String,
        approvalId: json['approvalId'] as String,
        fileKey: json['fileKey'] as String,
        thumbKey: json['thumbKey'] as String?,
        mimeType: json['mimeType'] as String,
        sizeBytes: (json['sizeBytes'] as num).toInt(),
        url: json['url'] as String?,
        thumbUrl: json['thumbUrl'] as String?,
      );
}

@freezed
class Approval with _$Approval {
  const factory Approval({
    required String id,
    required ApprovalScope scope,
    required String projectId,
    String? stageId,
    String? stepId,
    @Default(<String, dynamic>{}) Map<String, dynamic> payload,
    required String requestedById,
    required String addresseeId,
    required ApprovalStatus status,
    required int attemptNumber,
    @Default(false) bool requiresReassign,
    DateTime? decidedAt,
    String? decidedById,
    String? decisionComment,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(<ApprovalAttempt>[]) List<ApprovalAttempt> attempts,
    @Default(<ApprovalAttachment>[]) List<ApprovalAttachment> attachments,
  }) = _Approval;

  static Approval parse(Map<String, dynamic> json) => Approval(
        id: json['id'] as String,
        scope: ApprovalScope.fromString(json['scope'] as String?),
        projectId: json['projectId'] as String,
        stageId: json['stageId'] as String?,
        stepId: json['stepId'] as String?,
        payload:
            Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
        requestedById: json['requestedById'] as String? ?? '',
        addresseeId: json['addresseeId'] as String? ?? '',
        status: ApprovalStatus.fromString(json['status'] as String?),
        attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 1,
        requiresReassign: json['requiresReassign'] as bool? ?? false,
        decidedAt: _d(json['decidedAt']),
        decidedById: json['decidedById'] as String?,
        decisionComment: json['decisionComment'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        attempts: (json['attempts'] as List<dynamic>? ?? const [])
            .map((e) => ApprovalAttempt.parse(e as Map<String, dynamic>))
            .toList(),
        attachments: (json['attachments'] as List<dynamic>? ?? const [])
            .map((e) => ApprovalAttachment.parse(e as Map<String, dynamic>))
            .toList(),
      );
}

DateTime? _d(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;

/// Payload-хелперы — безопасный доступ к полям для каждого scope.
extension ApprovalPayloadX on Approval {
  /// scope=plan: payload.stages = [{stageId, title, plannedStart, plannedEnd}].
  List<Map<String, dynamic>> get planStages =>
      (payload['stages'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();

  /// scope=deadline_change: payload.newEnd (ISO).
  DateTime? get newEnd {
    final raw = payload['newEnd'];
    return raw is String ? DateTime.tryParse(raw) : null;
  }

  /// scope=extra_work: payload.price (копейки) + payload.description.
  int? get extraPrice => (payload['price'] as num?)?.toInt();
  String? get extraDescription => payload['description'] as String?;

  /// scope=stage_accept: payload.photoCount (итог).
  int? get acceptPhotoCount => (payload['photoCount'] as num?)?.toInt();
}
