import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/widgets/status_pill.dart';

part 'payment.freezed.dart';

enum PaymentKind {
  advance,
  distribution,
  correction;

  static PaymentKind fromString(String? raw) {
    switch (raw) {
      case 'distribution':
        return PaymentKind.distribution;
      case 'correction':
        return PaymentKind.correction;
      case 'advance':
      default:
        return PaymentKind.advance;
    }
  }

  String get apiValue => switch (this) {
        PaymentKind.advance => 'advance',
        PaymentKind.distribution => 'distribution',
        PaymentKind.correction => 'correction',
      };

  String get displayName => switch (this) {
        PaymentKind.advance => 'Аванс',
        PaymentKind.distribution => 'Выплата мастеру',
        PaymentKind.correction => 'Корректировка',
      };

  IconData get icon => switch (this) {
        PaymentKind.advance => Icons.north_east_rounded,
        PaymentKind.distribution => Icons.call_split_rounded,
        PaymentKind.correction => Icons.tune_rounded,
      };
}

enum PaymentStatus {
  pending,
  confirmed,
  disputed,
  resolved,
  cancelled;

  static PaymentStatus fromString(String? raw) {
    switch (raw) {
      case 'confirmed':
        return PaymentStatus.confirmed;
      case 'disputed':
        return PaymentStatus.disputed;
      case 'resolved':
        return PaymentStatus.resolved;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  String get apiValue => switch (this) {
        PaymentStatus.pending => 'pending',
        PaymentStatus.confirmed => 'confirmed',
        PaymentStatus.disputed => 'disputed',
        PaymentStatus.resolved => 'resolved',
        PaymentStatus.cancelled => 'cancelled',
      };

  String get displayName => switch (this) {
        PaymentStatus.pending => 'Ожидает',
        PaymentStatus.confirmed => 'Подтверждено',
        PaymentStatus.disputed => 'Спор',
        PaymentStatus.resolved => 'Решено',
        PaymentStatus.cancelled => 'Отменено',
      };

  Semaphore get semaphore => switch (this) {
        PaymentStatus.pending => Semaphore.blue,
        PaymentStatus.confirmed => Semaphore.green,
        PaymentStatus.disputed => Semaphore.red,
        PaymentStatus.resolved => Semaphore.plan,
        PaymentStatus.cancelled => Semaphore.plan,
      };
}

@freezed
class PaymentDispute with _$PaymentDispute {
  const factory PaymentDispute({
    required String id,
    required String paymentId,
    required String openedById,
    required String reason,
    required String status,
    String? resolution,
    DateTime? resolvedAt,
    String? resolvedBy,
    required DateTime createdAt,
  }) = _PaymentDispute;

  static PaymentDispute parse(Map<String, dynamic> json) => PaymentDispute(
        id: json['id'] as String,
        paymentId: json['paymentId'] as String,
        openedById: json['openedById'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        status: json['status'] as String? ?? 'open',
        resolution: json['resolution'] as String?,
        resolvedAt: _d(json['resolvedAt']),
        resolvedBy: json['resolvedBy'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

@freezed
class Payment with _$Payment {
  const factory Payment({
    required String id,
    required String projectId,
    String? stageId,
    String? parentPaymentId,
    required PaymentKind kind,
    required String fromUserId,
    required String toUserId,
    required int amount,
    int? resolvedAmount,
    String? comment,
    String? photoKey,
    required PaymentStatus status,
    DateTime? confirmedAt,
    DateTime? disputedAt,
    DateTime? resolvedAt,
    DateTime? cancelledAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(<Payment>[]) List<Payment> children,
    @Default(<PaymentDispute>[]) List<PaymentDispute> disputes,
  }) = _Payment;

  static Payment parse(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        stageId: json['stageId'] as String?,
        parentPaymentId: json['parentPaymentId'] as String?,
        kind: PaymentKind.fromString(json['kind'] as String?),
        fromUserId: json['fromUserId'] as String? ?? '',
        toUserId: json['toUserId'] as String? ?? '',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        resolvedAmount: (json['resolvedAmount'] as num?)?.toInt(),
        comment: json['comment'] as String?,
        photoKey: json['photoKey'] as String?,
        status: PaymentStatus.fromString(json['status'] as String?),
        confirmedAt: _d(json['confirmedAt']),
        disputedAt: _d(json['disputedAt']),
        resolvedAt: _d(json['resolvedAt']),
        cancelledAt: _d(json['cancelledAt']),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        children: (json['children'] as List<dynamic>? ?? const [])
            .map((e) => Payment.parse(e as Map<String, dynamic>))
            .toList(),
        disputes: (json['disputes'] as List<dynamic>? ?? const [])
            .map((e) => PaymentDispute.parse(e as Map<String, dynamic>))
            .toList(),
      );
}

DateTime? _d(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;

extension PaymentX on Payment {
  /// Активные children — backend отфильтровывает cancelled, мы зеркалим.
  Iterable<Payment> get activeChildren =>
      children.where((c) => c.status != PaymentStatus.cancelled);

  /// Сумма активных распределений с учётом resolve-корректировок.
  int get distributedAmount =>
      activeChildren.fold<int>(0, (acc, c) => acc + c.effectiveAmount);

  /// Сколько ещё можно распределить — учитывает корректировку родителя.
  int get remainingToDistribute => effectiveAmount - distributedAmount;

  /// Итоговая сумма с учётом resolve-корректировки.
  int get effectiveAmount => resolvedAmount ?? amount;

  /// Получатель — для удобной типизации в UI (chat avatar нужен toUserId).
  bool get isAdvance => kind == PaymentKind.advance;
  bool get isDistribution => kind == PaymentKind.distribution;
}
