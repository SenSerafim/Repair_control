// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch_document_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchDocumentDto _$PatchDocumentDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PatchDocumentDto', json, ($checkedConvert) {
      final val = PatchDocumentDto(
        title: $checkedConvert('title', (v) => v as String?),
        category: $checkedConvert(
          'category',
          (v) => $enumDecodeNullable(_$PatchDocumentDtoCategoryEnumEnumMap, v),
        ),
        stageId: $checkedConvert('stageId', (v) => v as String?),
        stepId: $checkedConvert('stepId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$PatchDocumentDtoToJson(PatchDocumentDto instance) =>
    <String, dynamic>{
      if (instance.title case final value?) 'title': value,
      if (_$PatchDocumentDtoCategoryEnumEnumMap[instance.category]
          case final value?)
        'category': value,
      if (instance.stageId case final value?) 'stageId': value,
      if (instance.stepId case final value?) 'stepId': value,
    };

const _$PatchDocumentDtoCategoryEnumEnumMap = {
  PatchDocumentDtoCategoryEnum.contract: 'contract',
  PatchDocumentDtoCategoryEnum.act: 'act',
  PatchDocumentDtoCategoryEnum.estimate: 'estimate',
  PatchDocumentDtoCategoryEnum.warranty: 'warranty',
  PatchDocumentDtoCategoryEnum.photo: 'photo',
  PatchDocumentDtoCategoryEnum.blueprint: 'blueprint',
  PatchDocumentDtoCategoryEnum.other: 'other',
};
