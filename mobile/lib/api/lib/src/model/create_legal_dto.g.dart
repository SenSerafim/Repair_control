// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_legal_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateLegalDto _$CreateLegalDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateLegalDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['kind', 'title', 'bodyMd']);
      final val = CreateLegalDto(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$CreateLegalDtoKindEnumEnumMap, v),
        ),
        title: $checkedConvert('title', (v) => v as String),
        bodyMd: $checkedConvert('bodyMd', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$CreateLegalDtoToJson(CreateLegalDto instance) =>
    <String, dynamic>{
      'kind': _$CreateLegalDtoKindEnumEnumMap[instance.kind]!,
      'title': instance.title,
      'bodyMd': instance.bodyMd,
    };

const _$CreateLegalDtoKindEnumEnumMap = {
  CreateLegalDtoKindEnum.privacy: 'privacy',
  CreateLegalDtoKindEnum.tos: 'tos',
  CreateLegalDtoKindEnum.dataProcessingConsent: 'data_processing_consent',
};
