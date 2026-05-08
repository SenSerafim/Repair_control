// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'return_tool_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReturnToolDto _$ReturnToolDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReturnToolDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['returnedQty']);
      final val = ReturnToolDto(
        returnedQty: $checkedConvert('returnedQty', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$ReturnToolDtoToJson(ReturnToolDto instance) =>
    <String, dynamic>{'returnedQty': instance.returnedQty};
