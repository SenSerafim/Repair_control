// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterDto _$RegisterDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RegisterDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'phone',
          'password',
          'firstName',
          'lastName',
          'role',
        ],
      );
      final val = RegisterDto(
        phone: $checkedConvert('phone', (v) => v as String),
        password: $checkedConvert('password', (v) => v as String),
        firstName: $checkedConvert('firstName', (v) => v as String),
        lastName: $checkedConvert('lastName', (v) => v as String),
        role: $checkedConvert(
          'role',
          (v) => $enumDecode(_$RegisterDtoRoleEnumEnumMap, v),
        ),
        language: $checkedConvert('language', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$RegisterDtoToJson(RegisterDto instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'password': instance.password,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'role': _$RegisterDtoRoleEnumEnumMap[instance.role]!,
      if (instance.language case final value?) 'language': value,
    };

const _$RegisterDtoRoleEnumEnumMap = {
  RegisterDtoRoleEnum.customer: 'customer',
  RegisterDtoRoleEnum.representative: 'representative',
  RegisterDtoRoleEnum.contractor: 'contractor',
  RegisterDtoRoleEnum.master: 'master',
};
