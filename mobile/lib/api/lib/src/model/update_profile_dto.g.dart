// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateProfileDto _$UpdateProfileDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateProfileDto', json, ($checkedConvert) {
      final val = UpdateProfileDto(
        firstName: $checkedConvert('firstName', (v) => v as String?),
        lastName: $checkedConvert('lastName', (v) => v as String?),
        avatarUrl: $checkedConvert('avatarUrl', (v) => v),
        language: $checkedConvert('language', (v) => v as String?),
        email: $checkedConvert('email', (v) => v),
      );
      return val;
    });

Map<String, dynamic> _$UpdateProfileDtoToJson(UpdateProfileDto instance) =>
    <String, dynamic>{
      if (instance.firstName case final value?) 'firstName': value,
      if (instance.lastName case final value?) 'lastName': value,
      if (instance.avatarUrl case final value?) 'avatarUrl': value,
      if (instance.language case final value?) 'language': value,
      if (instance.email case final value?) 'email': value,
    };
