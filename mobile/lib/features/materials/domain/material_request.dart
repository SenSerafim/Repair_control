import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/widgets/status_pill.dart';

part 'material_request.freezed.dart';

enum MaterialRecipient {
  foreman,
  customer;

  static MaterialRecipient fromString(String? raw) =>
      raw == 'customer' ? MaterialRecipient.customer : MaterialRecipient.foreman;

  String get apiValue => switch (this) {
        MaterialRecipient.foreman => 'foreman',
        MaterialRecipient.customer => 'customer',
      };

  String get displayName => switch (this) {
        MaterialRecipient.foreman => 'Бригадир покупает',
        MaterialRecipient.customer => 'Заказчик покупает',
      };
}

enum MaterialRequestStatus {
  draft,
  open,
  partiallyBought,
  bought,
  delivered,
  disputed,
  resolved,
  cancelled;

  static MaterialRequestStatus fromString(String? raw) {
    switch (raw) {
      case 'open':
        return MaterialRequestStatus.open;
      case 'partially_bought':
        return MaterialRequestStatus.partiallyBought;
      case 'bought':
        return MaterialRequestStatus.bought;
      case 'delivered':
        return MaterialRequestStatus.delivered;
      case 'disputed':
        return MaterialRequestStatus.disputed;
      case 'resolved':
        return MaterialRequestStatus.resolved;
      case 'cancelled':
        return MaterialRequestStatus.cancelled;
      case 'draft':
      default:
        return MaterialRequestStatus.draft;
    }
  }

  String get apiValue => switch (this) {
        MaterialRequestStatus.draft => 'draft',
        MaterialRequestStatus.open => 'open',
        MaterialRequestStatus.partiallyBought => 'partially_bought',
        MaterialRequestStatus.bought => 'bought',
        MaterialRequestStatus.delivered => 'delivered',
        MaterialRequestStatus.disputed => 'disputed',
        MaterialRequestStatus.resolved => 'resolved',
        MaterialRequestStatus.cancelled => 'cancelled',
      };

  String get displayName => switch (this) {
        MaterialRequestStatus.draft => 'Черновик',
        MaterialRequestStatus.open => 'Отправлено',
        MaterialRequestStatus.partiallyBought => 'Частично куплено',
        MaterialRequestStatus.bought => 'Куплено',
        MaterialRequestStatus.delivered => 'Доставлено',
        MaterialRequestStatus.disputed => 'Спор',
        MaterialRequestStatus.resolved => 'Решено',
        MaterialRequestStatus.cancelled => 'Отменено',
      };

  Semaphore get semaphore => switch (this) {
        MaterialRequestStatus.draft => Semaphore.plan,
        MaterialRequestStatus.open => Semaphore.blue,
        MaterialRequestStatus.partiallyBought => Semaphore.yellow,
        MaterialRequestStatus.bought => Semaphore.green,
        MaterialRequestStatus.delivered => Semaphore.green,
        MaterialRequestStatus.disputed => Semaphore.red,
        MaterialRequestStatus.resolved => Semaphore.plan,
        MaterialRequestStatus.cancelled => Semaphore.plan,
      };

  bool get isTerminal =>
      this == MaterialRequestStatus.resolved ||
      this == MaterialRequestStatus.cancelled ||
      this == MaterialRequestStatus.delivered;
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
class MaterialDispute with _$MaterialDispute {
  const factory MaterialDispute({
    required String id,
    required String requestId,
    required String openedById,
    required String reason,
    required String status,
    String? resolution,
    DateTime? resolvedAt,
    String? resolvedBy,
    required DateTime createdAt,
  }) = _MaterialDispute;

  static MaterialDispute parse(Map<String, dynamic> json) => MaterialDispute(
        id: json['id'] as String,
        requestId: json['requestId'] as String,
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
    @Default(<MaterialDispute>[]) List<MaterialDispute> disputes,
  }) = _MaterialRequest;

  static MaterialRequest parse(Map<String, dynamic> json) => MaterialRequest(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        stageId: json['stageId'] as String?,
        createdById: json['createdById'] as String? ?? '',
        recipient:
            MaterialRecipient.fromString(json['recipient'] as String?),
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
        disputes: (json['disputes'] as List<dynamic>? ?? const [])
            .map((e) => MaterialDispute.parse(e as Map<String, dynamic>))
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
  int get boughtItemsCount => items.where((i) => i.isBought).length;

  int get totalBoughtPrice => items
      .where((i) => i.isBought && i.totalPrice != null)
      .fold<int>(0, (acc, i) => acc + (i.totalPrice ?? 0));

  bool get allItemsBought =>
      items.isNotEmpty && items.every((i) => i.isBought);

  bool get isFinalized => finalizedAt != null;
}
