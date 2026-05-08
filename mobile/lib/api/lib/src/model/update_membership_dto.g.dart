// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_membership_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateMembershipDto _$UpdateMembershipDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateMembershipDto', json, ($checkedConvert) {
      final val = UpdateMembershipDto(
        permissions: $checkedConvert('permissions', (v) => v),
        stageIds: $checkedConvert(
          'stageIds',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$UpdateMembershipDtoToJson(
  UpdateMembershipDto instance,
) => <String, dynamic>{
  if (instance.permissions case final value?) 'permissions': value,
  if (instance.stageIds case final value?) 'stageIds': value,
};
