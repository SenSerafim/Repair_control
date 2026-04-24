import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/widgets/status_pill.dart';

part 'tool.freezed.dart';

enum ToolIssuanceStatus {
  issued,
  confirmed,
  returnRequested,
  returned;

  static ToolIssuanceStatus fromString(String? raw) {
    switch (raw) {
      case 'confirmed':
        return ToolIssuanceStatus.confirmed;
      case 'return_requested':
        return ToolIssuanceStatus.returnRequested;
      case 'returned':
        return ToolIssuanceStatus.returned;
      case 'issued':
      default:
        return ToolIssuanceStatus.issued;
    }
  }

  String get apiValue => switch (this) {
        ToolIssuanceStatus.issued => 'issued',
        ToolIssuanceStatus.confirmed => 'confirmed',
        ToolIssuanceStatus.returnRequested => 'return_requested',
        ToolIssuanceStatus.returned => 'returned',
      };

  String get displayName => switch (this) {
        ToolIssuanceStatus.issued => 'Выдан',
        ToolIssuanceStatus.confirmed => 'Подтверждён',
        ToolIssuanceStatus.returnRequested => 'Возврат',
        ToolIssuanceStatus.returned => 'Возвращён',
      };

  Semaphore get semaphore => switch (this) {
        ToolIssuanceStatus.issued => Semaphore.blue,
        ToolIssuanceStatus.confirmed => Semaphore.green,
        ToolIssuanceStatus.returnRequested => Semaphore.yellow,
        ToolIssuanceStatus.returned => Semaphore.plan,
      };
}

@freezed
class ToolItem with _$ToolItem {
  const factory ToolItem({
    required String id,
    required String ownerId,
    required String name,
    required int totalQty,
    required int issuedQty,
    String? unit,
    String? photoKey,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ToolItem;

  static ToolItem parse(Map<String, dynamic> json) => ToolItem(
        id: json['id'] as String,
        ownerId: json['ownerId'] as String? ?? '',
        name: json['name'] as String,
        totalQty: (json['totalQty'] as num?)?.toInt() ?? 0,
        issuedQty: (json['issuedQty'] as num?)?.toInt() ?? 0,
        unit: json['unit'] as String?,
        photoKey: json['photoKey'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

extension ToolItemX on ToolItem {
  int get availableQty => totalQty - issuedQty;
  bool get isAllIssued => issuedQty >= totalQty;
}

@freezed
class ToolIssuance with _$ToolIssuance {
  const factory ToolIssuance({
    required String id,
    required String toolItemId,
    String? projectId,
    String? stageId,
    required String toUserId,
    required String issuedById,
    required int qty,
    int? returnedQty,
    required ToolIssuanceStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    ToolItem? tool,
  }) = _ToolIssuance;

  static ToolIssuance parse(Map<String, dynamic> json) => ToolIssuance(
        id: json['id'] as String,
        toolItemId: json['toolItemId'] as String,
        projectId: json['projectId'] as String?,
        stageId: json['stageId'] as String?,
        toUserId: json['toUserId'] as String? ?? '',
        issuedById: json['issuedById'] as String? ?? '',
        qty: (json['qty'] as num?)?.toInt() ?? 0,
        returnedQty: (json['returnedQty'] as num?)?.toInt(),
        status: ToolIssuanceStatus.fromString(json['status'] as String?),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        tool: json['tool'] is Map<String, dynamic>
            ? ToolItem.parse(json['tool'] as Map<String, dynamic>)
            : null,
      );
}
