// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refresh_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefreshDto _$RefreshDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RefreshDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['refreshToken']);
      final val = RefreshDto(
        refreshToken: $checkedConvert('refreshToken', (v) => v as String),
        deviceId: $checkedConvert('deviceId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$RefreshDtoToJson(RefreshDto instance) =>
    <String, dynamic>{
      'refreshToken': instance.refreshToken,
      if (instance.deviceId case final value?) 'deviceId': value,
    };
