// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_member_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddMemberDto _$AddMemberDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AddMemberDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['userId', 'role']);
      final val = AddMemberDto(
        userId: $checkedConvert('userId', (v) => v as String),
        role: $checkedConvert(
          'role',
          (v) => $enumDecode(_$AddMemberDtoRoleEnumEnumMap, v),
        ),
        permissions: $checkedConvert('permissions', (v) => v),
        stageIds: $checkedConvert(
          'stageIds',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AddMemberDtoToJson(AddMemberDto instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'role': _$AddMemberDtoRoleEnumEnumMap[instance.role]!,
      if (instance.permissions case final value?) 'permissions': value,
      if (instance.stageIds case final value?) 'stageIds': value,
    };

const _$AddMemberDtoRoleEnumEnumMap = {
  AddMemberDtoRoleEnum.customer: 'customer',
  AddMemberDtoRoleEnum.representative: 'representative',
  AddMemberDtoRoleEnum.foreman: 'foreman',
  AddMemberDtoRoleEnum.master: 'master',
};
