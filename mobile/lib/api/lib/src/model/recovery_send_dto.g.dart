// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recovery_send_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecoverySendDto _$RecoverySendDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RecoverySendDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['phone']);
      final val = RecoverySendDto(
        phone: $checkedConvert('phone', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$RecoverySendDtoToJson(RecoverySendDto instance) =>
    <String, dynamic>{'phone': instance.phone};
