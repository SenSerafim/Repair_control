import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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

/// Платёж в упрощённой модели (2026-05-12) — факт передачи денег.
///
/// Заказчик/представитель создаёт `advance` напрямую foreman или master.
/// Бригадир из полученных авансов создаёт `distribution` мастерам.
/// Никаких подтверждений, отмен, споров — запись создана = деньги переданы.
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
    String? comment,
    String? photoKey,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(<Payment>[]) List<Payment> children,
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
    comment: json['comment'] as String?,
    photoKey: json['photoKey'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    children: (json['children'] as List<dynamic>? ?? const [])
        .map((e) => Payment.parse(e as Map<String, dynamic>))
        .toList(),
  );
}

extension PaymentX on Payment {
  /// Суммарно распределено по родительскому авансу.
  int get distributedAmount =>
      children.fold<int>(0, (acc, c) => acc + c.amount);

  /// Остаток к распределению. Может быть отрицательным, если бригадир
  /// раздал больше, чем получил — это допускается (warning, не блок).
  int get remainingToDistribute => amount - distributedAmount;

  bool get isAdvance => kind == PaymentKind.advance;
  bool get isDistribution => kind == PaymentKind.distribution;
}
