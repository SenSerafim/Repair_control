// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ban_user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BanUserDto _$BanUserDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BanUserDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason']);
      final val = BanUserDto(
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$BanUserDtoToJson(BanUserDto instance) =>
    <String, dynamic>{'reason': instance.reason};
