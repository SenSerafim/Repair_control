// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispute_material_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisputeMaterialDto _$DisputeMaterialDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DisputeMaterialDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason']);
      final val = DisputeMaterialDto(
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DisputeMaterialDtoToJson(DisputeMaterialDto instance) =>
    <String, dynamic>{'reason': instance.reason};
