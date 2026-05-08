// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recovery_reset_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecoveryResetDto _$RecoveryResetDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RecoveryResetDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['phone', 'code', 'newPassword']);
      final val = RecoveryResetDto(
        phone: $checkedConvert('phone', (v) => v as String),
        code: $checkedConvert('code', (v) => v as String),
        newPassword: $checkedConvert('newPassword', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$RecoveryResetDtoToJson(RecoveryResetDto instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'code': instance.code,
      'newPassword': instance.newPassword,
    };
