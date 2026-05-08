// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginDto _$LoginDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LoginDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['phone', 'password']);
      final val = LoginDto(
        phone: $checkedConvert('phone', (v) => v as String),
        password: $checkedConvert('password', (v) => v as String),
        deviceId: $checkedConvert('deviceId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$LoginDtoToJson(LoginDto instance) => <String, dynamic>{
  'phone': instance.phone,
  'password': instance.password,
  if (instance.deviceId case final value?) 'deviceId': value,
};
