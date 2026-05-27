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

/// FSM заявки 2.0 — ТЗ NEWFIX §5.7.
///
///   pendingApproval ─approve──▶ approved ─mark-delivered─▶ delivered
///         │                          ▲                        │
///         │                          │ (довоз)                ▼
///         └──reject──▶ rejected      └──mark-delivered── acceptedPartial
///                                                             ▼
///                                                       acceptedFull
///
/// Состояние `overdue` — НЕ хранится в БД, а computed на клиенте по
/// `MaterialItem.dueDate < now && status == approved`. См. `isOverdue`.
///
/// NB: на бэке используется enum БД, где `approved` сохранён как `open`.
/// Маппинг — здесь же.
enum MaterialRequestStatus {
  pendingApproval,
  approved,
  delivered,
  acceptedPartial,
  acceptedFull,
  rejected;

  static MaterialRequestStatus fromString(String? raw) {
    switch (raw) {
      case 'pending_approval':
        return MaterialRequestStatus.pendingApproval;
      case 'delivered':
        return MaterialRequestStatus.delivered;
      case 'accepted_partial':
        return MaterialRequestStatus.acceptedPartial;
      case 'accepted_full':
        return MaterialRequestStatus.acceptedFull;
      case 'cancelled':
        return MaterialRequestStatus.rejected;
      // 'open' и историческое 'bought' / 'resolved' — всё «Согласовано».
      default:
        return MaterialRequestStatus.approved;
    }
  }

  String get apiValue => switch (this) {
    MaterialRequestStatus.pendingApproval => 'pending_approval',
    MaterialRequestStatus.approved => 'open',
    MaterialRequestStatus.delivered => 'delivered',
    MaterialRequestStatus.acceptedPartial => 'accepted_partial',
    MaterialRequestStatus.acceptedFull => 'accepted_full',
    MaterialRequestStatus.rejected => 'cancelled',
  };

  String get displayName => switch (this) {
    MaterialRequestStatus.pendingApproval => 'Ждёт согласования',
    MaterialRequestStatus.approved => 'Согласовано',
    MaterialRequestStatus.delivered => 'Доставлено · ждёт приёмки',
    MaterialRequestStatus.acceptedPartial => 'Принято частично',
    MaterialRequestStatus.acceptedFull => 'Принято полностью',
    MaterialRequestStatus.rejected => 'Отклонено',
  };

  Semaphore get semaphore => switch (this) {
    MaterialRequestStatus.pendingApproval => Semaphore.plan,
    MaterialRequestStatus.approved => Semaphore.green,
    MaterialRequestStatus.delivered => Semaphore.blue,
    MaterialRequestStatus.acceptedPartial => Semaphore.yellow,
    MaterialRequestStatus.acceptedFull => Semaphore.green,
    MaterialRequestStatus.rejected => Semaphore.red,
  };

  /// Заявка закрыта (положительно или отказом) — кнопок действия нет.
  bool get isTerminal =>
      this == MaterialRequestStatus.acceptedFull ||
      this == MaterialRequestStatus.rejected;
}

@freezed
class MaterialItemPhoto with _$MaterialItemPhoto {
  const factory MaterialItemPhoto({
    required String id,
    required String fileKey,
    String? thumbKey,
    required String mimeType,
    required int sizeBytes,
    required String uploadedBy,
    required bool exifCleared,
    required DateTime createdAt,
  }) = _MaterialItemPhoto;

  static MaterialItemPhoto parse(Map<String, dynamic> json) => MaterialItemPhoto(
    id: json['id'] as String,
    fileKey: json['fileKey'] as String,
    thumbKey: json['thumbKey'] as String?,
    mimeType: json['mimeType'] as String,
    sizeBytes: (json['sizeBytes'] as num).toInt(),
    uploadedBy: json['uploadedBy'] as String,
    exifCleared: json['exifCleared'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

@freezed
class MaterialItem with _$MaterialItem {
  const factory MaterialItem({
    required String id,
    required String requestId,
    required String name,
    required double qty,
    /// Фактически принятое количество (заполняется при accept-partial/full).
    /// null до приёмки. ТЗ NEWFIX §5.7.
    double? actualQty,
    String? unit,
    String? note,
    int? pricePerUnit,
    int? totalPrice,
    /// Срок поставки позиции. ТЗ NEWFIX §5.5. Если прошёл а status=open,
    /// клиент показывает стикер «Просрочена», бэк эмитит push раз в сутки.
    DateTime? dueDate,
    MaterialItemPhoto? photo,
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
    actualQty: _toDouble(json['actualQty']),
    unit: json['unit'] as String?,
    note: json['note'] as String?,
    pricePerUnit: (json['pricePerUnit'] as num?)?.toInt(),
    totalPrice: (json['totalPrice'] as num?)?.toInt(),
    dueDate: _d(json['dueDate']),
    photo: json['photo'] is Map<String, dynamic>
        ? MaterialItemPhoto.parse(json['photo'] as Map<String, dynamic>)
        : null,
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

  /// Заявка просрочена: статус «Согласовано» и есть позиция с прошедшей
  /// dueDate. ТЗ NEWFIX §5.5 — стикер «Просрочена» на карточке.
  bool isOverdue(DateTime now) {
    if (status != MaterialRequestStatus.approved) return false;
    return items.any((i) => i.dueDate != null && i.dueDate!.isBefore(now));
  }

  /// true если можно отметить «Доставлено» (master/foreman/customer). FSM:
  /// approved → delivered, accepted_partial → delivered (довоз остатка).
  bool get canMarkDelivered =>
      status == MaterialRequestStatus.approved ||
      status == MaterialRequestStatus.acceptedPartial;

  /// true если можно принять (foreman/customer): только из delivered.
  bool get canAccept => status == MaterialRequestStatus.delivered;
}
