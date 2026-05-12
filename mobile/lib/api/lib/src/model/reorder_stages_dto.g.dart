// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reorder_stages_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReorderStagesDto _$ReorderStagesDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReorderStagesDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ReorderStagesDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ReorderItemDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ReorderStagesDtoToJson(ReorderStagesDto instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
