// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_tool_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateToolDto _$UpdateToolDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateToolDto', json, ($checkedConvert) {
      final val = UpdateToolDto(
        name: $checkedConvert('name', (v) => v as String?),
        totalQty: $checkedConvert('totalQty', (v) => v as num?),
        unit: $checkedConvert('unit', (v) => v as String?),
        photoKey: $checkedConvert('photoKey', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$UpdateToolDtoToJson(UpdateToolDto instance) =>
    <String, dynamic>{
      if (instance.name case final value?) 'name': value,
      if (instance.totalQty case final value?) 'totalQty': value,
      if (instance.unit case final value?) 'unit': value,
      if (instance.photoKey case final value?) 'photoKey': value,
    };
