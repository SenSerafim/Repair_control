// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reorder_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReorderItemDto _$ReorderItemDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReorderItemDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'orderIndex']);
      final val = ReorderItemDto(
        id: $checkedConvert('id', (v) => v as String),
        orderIndex: $checkedConvert('orderIndex', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$ReorderItemDtoToJson(ReorderItemDto instance) =>
    <String, dynamic>{'id': instance.id, 'orderIndex': instance.orderIndex};
