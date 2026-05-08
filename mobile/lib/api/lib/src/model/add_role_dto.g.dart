// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_role_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddRoleDto _$AddRoleDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AddRoleDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['role']);
      final val = AddRoleDto(
        role: $checkedConvert(
          'role',
          (v) => $enumDecode(_$AddRoleDtoRoleEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AddRoleDtoToJson(AddRoleDto instance) =>
    <String, dynamic>{'role': _$AddRoleDtoRoleEnumEnumMap[instance.role]!};

const _$AddRoleDtoRoleEnumEnumMap = {
  AddRoleDtoRoleEnum.customer: 'customer',
  AddRoleDtoRoleEnum.representative: 'representative',
  AddRoleDtoRoleEnum.contractor: 'contractor',
  AddRoleDtoRoleEnum.master: 'master',
};
