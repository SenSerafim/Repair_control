// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recovery_verify_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecoveryVerifyDto _$RecoveryVerifyDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RecoveryVerifyDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['phone', 'code']);
      final val = RecoveryVerifyDto(
        phone: $checkedConvert('phone', (v) => v as String),
        code: $checkedConvert('code', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$RecoveryVerifyDtoToJson(RecoveryVerifyDto instance) =>
    <String, dynamic>{'phone': instance.phone, 'code': instance.code};
