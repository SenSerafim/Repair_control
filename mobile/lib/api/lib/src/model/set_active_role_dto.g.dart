// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_active_role_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetActiveRoleDto _$SetActiveRoleDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SetActiveRoleDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['role']);
      final val = SetActiveRoleDto(
        role: $checkedConvert(
          'role',
          (v) => $enumDecode(_$SetActiveRoleDtoRoleEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SetActiveRoleDtoToJson(SetActiveRoleDto instance) =>
    <String, dynamic>{
      'role': _$SetActiveRoleDtoRoleEnumEnumMap[instance.role]!,
    };

const _$SetActiveRoleDtoRoleEnumEnumMap = {
  SetActiveRoleDtoRoleEnum.customer: 'customer',
  SetActiveRoleDtoRoleEnum.representative: 'representative',
  SetActiveRoleDtoRoleEnum.contractor: 'contractor',
  SetActiveRoleDtoRoleEnum.master: 'master',
};
