// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_legal_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcceptLegalDto _$AcceptLegalDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AcceptLegalDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['kind']);
      final val = AcceptLegalDto(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$AcceptLegalDtoKindEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AcceptLegalDtoToJson(AcceptLegalDto instance) =>
    <String, dynamic>{'kind': _$AcceptLegalDtoKindEnumEnumMap[instance.kind]!};

const _$AcceptLegalDtoKindEnumEnumMap = {
  AcceptLegalDtoKindEnum.privacy: 'privacy',
  AcceptLegalDtoKindEnum.tos: 'tos',
  AcceptLegalDtoKindEnum.dataProcessingConsent: 'data_processing_consent',
};
