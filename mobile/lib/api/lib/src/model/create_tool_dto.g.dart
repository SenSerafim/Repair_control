// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_tool_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateToolDto _$CreateToolDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateToolDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name', 'totalQty']);
      final val = CreateToolDto(
        name: $checkedConvert('name', (v) => v as String),
        totalQty: $checkedConvert('totalQty', (v) => v as num),
        unit: $checkedConvert('unit', (v) => v as String?),
        photoKey: $checkedConvert('photoKey', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CreateToolDtoToJson(CreateToolDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'totalQty': instance.totalQty,
      if (instance.unit case final value?) 'unit': value,
      if (instance.photoKey case final value?) 'photoKey': value,
    };
