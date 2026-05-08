// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logout_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogoutDto _$LogoutDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LogoutDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['refreshToken']);
      final val = LogoutDto(
        refreshToken: $checkedConvert('refreshToken', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$LogoutDtoToJson(LogoutDto instance) => <String, dynamic>{
  'refreshToken': instance.refreshToken,
};
