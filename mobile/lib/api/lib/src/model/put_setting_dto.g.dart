// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'put_setting_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PutSettingDto _$PutSettingDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PutSettingDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['key', 'value']);
      final val = PutSettingDto(
        key: $checkedConvert('key', (v) => v as String),
        value: $checkedConvert('value', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PutSettingDtoToJson(PutSettingDto instance) =>
    <String, dynamic>{'key': instance.key, 'value': instance.value};
