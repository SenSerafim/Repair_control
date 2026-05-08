// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_device_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterDeviceDto _$RegisterDeviceDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RegisterDeviceDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['platform', 'token']);
      final val = RegisterDeviceDto(
        platform: $checkedConvert(
          'platform',
          (v) => $enumDecode(_$RegisterDeviceDtoPlatformEnumEnumMap, v),
        ),
        token: $checkedConvert('token', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$RegisterDeviceDtoToJson(RegisterDeviceDto instance) =>
    <String, dynamic>{
      'platform': _$RegisterDeviceDtoPlatformEnumEnumMap[instance.platform]!,
      'token': instance.token,
    };

const _$RegisterDeviceDtoPlatformEnumEnumMap = {
  RegisterDeviceDtoPlatformEnum.ios: 'ios',
  RegisterDeviceDtoPlatformEnum.android: 'android',
};
