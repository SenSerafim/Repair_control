import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/widgets/status_pill.dart';

part 'material_request.freezed.dart';

enum MaterialRecipient {
  foreman,
  customer;

  static MaterialRecipient fromString(String? raw) => raw == 'customer'
      ? MaterialRecipient.customer
      : MaterialRecipient.foreman;

  String get apiValue => switch (this) {
    MaterialRecipient.foreman => 'foreman',
    MaterialRecipient.customer => 'customer',
  };

  String get displayName => switch (this) {
    MaterialRecipient.foreman => 'Бригадир покупает',
    MaterialRecipient.customer => 'Заказчик покупает',
  };
}

/// Простой FSM (UI/UX-упрощение 2026-05):
///   pendingApproval ──approve──▶ approved
///         │
///         └──reject──▶ rejected
///
/// Все участники проекта (заказчик, представитель, бригадир, мастер) видят
/// заявку сразу после создания, включая отклонения от заказчика.
///
/// NB: на бэке используется оригинальный enum БД, где `approved` сохранён
/// как `open`, а `rejected` — как `cancelled`. Маппинг — здесь же.
enum MaterialRequestStatus {
  pendingApproval,
  approved,
  rejected;

  static MaterialRequestStatus fromString(String? raw) {
    switch (raw) {
      case 'pending_approval':
        return MaterialRequestStatus.pendingApproval;
      case 'cancelled':
        return MaterialRequestStatus.rejected;
      // 'open' + наследие ('bought'/'delivered'/'resolved') — всё «Согласовано».
      default:
        return MaterialRequestStatus.approved;
    }
  }

  String get apiValue => switch (this) {
    MaterialRequestStatus.pendingApproval => 'pending_approval',
    MaterialRequestStatus.approved => 'open',
    MaterialRequestStatus.rejected => 'cancelled',
  };

  String get displayName => switch (this) {
    MaterialRequestStatus.pendingApproval => 'Ждёт согласования',
    MaterialRequestStatus.approved => 'Согласовано',
    MaterialRequestStatus.rejected => 'Отклонено',
  };

  Semaphore get semaphore => switch (this) {
    MaterialRequestStatus.pendingApproval => Semaphore.plan,
    MaterialRequestStatus.approved => Semaphore.green,
    MaterialRequestStatus.rejected => Semaphore.plan,
  };

  bool get isTerminal => this != MaterialRequestStatus.pendingApproval;
}

@freezed
class MaterialItem with _$MaterialItem {
  const factory MaterialItem({
    required String id,
    required String requestId,
    required String name,
    required double qty,
    String? unit,
    String? note,
    int? pricePerUnit,
    int? totalPrice,
    required bool isBought,
    DateTime? boughtAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MaterialItem;

  static MaterialItem parse(Map<String, dynamic> json) => MaterialItem(
    id: json['id'] as String,
    requestId: json['requestId'] as String,
    name: json['name'] as String,
    qty: _toDouble(json['qty']) ?? 0,
    unit: json['unit'] as String?,
    note: json['note'] as String?,
    pricePerUnit: (json['pricePerUnit'] as num?)?.toInt(),
    totalPrice: (json['totalPrice'] as num?)?.toInt(),
    isBought: json['isBought'] as bool? ?? false,
    boughtAt: _d(json['boughtAt']),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

@freezed
class MaterialRequest with _$MaterialRequest {
  const factory MaterialRequest({
    required String id,
    required String projectId,
    String? stageId,
    required String createdById,
    required MaterialRecipient recipient,
    required String title,
    String? comment,
    required MaterialRequestStatus status,
    DateTime? finalizedAt,
    DateTime? deliveredAt,
    String? deliveredById,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(<MaterialItem>[]) List<MaterialItem> items,
  }) = _MaterialRequest;

  static MaterialRequest parse(Map<String, dynamic> json) => MaterialRequest(
    id: json['id'] as String,
    projectId: json['projectId'] as String,
    stageId: json['stageId'] as String?,
    createdById: json['createdById'] as String? ?? '',
    recipient: MaterialRecipient.fromString(json['recipient'] as String?),
    title: json['title'] as String,
    comment: json['comment'] as String?,
    status: MaterialRequestStatus.fromString(json['status'] as String?),
    finalizedAt: _d(json['finalizedAt']),
    deliveredAt: _d(json['deliveredAt']),
    deliveredById: json['deliveredById'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((e) => MaterialItem.parse(e as Map<String, dynamic>))
        .toList(),
  );
}

DateTime? _d(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;

double? _toDouble(Object? raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}

extension MaterialRequestX on MaterialRequest {
  /// Сумма по всем позициям (qty × pricePerUnit). Отображается в карточке и
  /// списках; для approved заявок попадает в materialsSpent проекта.
  int get totalEstimatedPrice =>
      items.fold<int>(0, (acc, i) => acc + (i.totalPrice ?? 0));
}
