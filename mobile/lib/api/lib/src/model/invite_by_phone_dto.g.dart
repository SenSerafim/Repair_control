// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_by_phone_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteByPhoneDto _$InviteByPhoneDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('InviteByPhoneDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['phone', 'role']);
      final val = InviteByPhoneDto(
        phone: $checkedConvert('phone', (v) => v as String),
        role: $checkedConvert(
          'role',
          (v) => $enumDecode(_$InviteByPhoneDtoRoleEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$InviteByPhoneDtoToJson(InviteByPhoneDto instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'role': _$InviteByPhoneDtoRoleEnumEnumMap[instance.role]!,
    };

const _$InviteByPhoneDtoRoleEnumEnumMap = {
  InviteByPhoneDtoRoleEnum.customer: 'customer',
  InviteByPhoneDtoRoleEnum.representative: 'representative',
  InviteByPhoneDtoRoleEnum.foreman: 'foreman',
  InviteByPhoneDtoRoleEnum.master: 'master',
};
