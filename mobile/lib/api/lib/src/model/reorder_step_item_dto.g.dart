// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reorder_step_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReorderStepItemDto _$ReorderStepItemDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReorderStepItemDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'orderIndex']);
      final val = ReorderStepItemDto(
        id: $checkedConvert('id', (v) => v as String),
        orderIndex: $checkedConvert('orderIndex', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$ReorderStepItemDtoToJson(ReorderStepItemDto instance) =>
    <String, dynamic>{'id': instance.id, 'orderIndex': instance.orderIndex};
