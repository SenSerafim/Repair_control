import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/widgets/status_pill.dart';

part 'self_purchase.freezed.dart';

enum SelfPurchaseStatus {
  pending,
  approved,
  rejected;

  static SelfPurchaseStatus fromString(String? raw) {
    switch (raw) {
      case 'approved':
        return SelfPurchaseStatus.approved;
      case 'rejected':
        return SelfPurchaseStatus.rejected;
      case 'pending':
      default:
        return SelfPurchaseStatus.pending;
    }
  }

  String get apiValue => switch (this) {
        SelfPurchaseStatus.pending => 'pending',
        SelfPurchaseStatus.approved => 'approved',
        SelfPurchaseStatus.rejected => 'rejected',
      };

  String get displayName => switch (this) {
        SelfPurchaseStatus.pending => 'На согласовании',
        SelfPurchaseStatus.approved => 'Подтверждено',
        SelfPurchaseStatus.rejected => 'Отклонено',
      };

  Semaphore get semaphore => switch (this) {
        SelfPurchaseStatus.pending => Semaphore.blue,
        SelfPurchaseStatus.approved => Semaphore.green,
        SelfPurchaseStatus.rejected => Semaphore.red,
      };
}

enum SelfPurchaseBy {
  foreman,
  master;

  static SelfPurchaseBy fromString(String? raw) =>
      raw == 'foreman' ? SelfPurchaseBy.foreman : SelfPurchaseBy.master;

  String get apiValue => switch (this) {
        SelfPurchaseBy.foreman => 'foreman',
        SelfPurchaseBy.master => 'master',
      };

  String get displayName => switch (this) {
        SelfPurchaseBy.foreman => 'Бригадир',
        SelfPurchaseBy.master => 'Мастер',
      };
}

@freezed
class SelfPurchase with _$SelfPurchase {
  const factory SelfPurchase({
    required String id,
    required String projectId,
    String? stageId,
    required String byUserId,
    required SelfPurchaseBy byRole,
    required String addresseeId,
    required int amount,
    String? comment,
    @Default(<String>[]) List<String> photoKeys,
    required SelfPurchaseStatus status,
    DateTime? decidedAt,
    String? decidedById,
    String? decisionComment,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SelfPurchase;

  static SelfPurchase parse(Map<String, dynamic> json) => SelfPurchase(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        stageId: json['stageId'] as String?,
        byUserId: json['byUserId'] as String? ?? '',
        byRole: SelfPurchaseBy.fromString(json['byRole'] as String?),
        addresseeId: json['addresseeId'] as String? ?? '',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        comment: json['comment'] as String?,
        photoKeys: (json['photoKeys'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        status: SelfPurchaseStatus.fromString(json['status'] as String?),
        decidedAt: _d(json['decidedAt']),
        decidedById: json['decidedById'] as String?,
        decisionComment: json['decisionComment'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

DateTime? _d(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;
