// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resolve_material_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResolveMaterialDto _$ResolveMaterialDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ResolveMaterialDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['resolution']);
      final val = ResolveMaterialDto(
        resolution: $checkedConvert('resolution', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ResolveMaterialDtoToJson(ResolveMaterialDto instance) =>
    <String, dynamic>{'resolution': instance.resolution};
