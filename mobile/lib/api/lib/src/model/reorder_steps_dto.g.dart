// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reorder_steps_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReorderStepsDto _$ReorderStepsDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReorderStepsDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ReorderStepsDto(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => ReorderStepItemDto.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ReorderStepsDtoToJson(ReorderStepsDto instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
