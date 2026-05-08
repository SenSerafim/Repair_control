// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presign_upload_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresignUploadDto _$PresignUploadDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PresignUploadDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['category', 'title', 'mimeType', 'sizeBytes'],
      );
      final val = PresignUploadDto(
        category: $checkedConvert(
          'category',
          (v) => $enumDecode(_$PresignUploadDtoCategoryEnumEnumMap, v),
        ),
        title: $checkedConvert('title', (v) => v as String),
        mimeType: $checkedConvert('mimeType', (v) => v as String),
        sizeBytes: $checkedConvert('sizeBytes', (v) => v as num),
        stageId: $checkedConvert('stageId', (v) => v as String?),
        stepId: $checkedConvert('stepId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$PresignUploadDtoToJson(PresignUploadDto instance) =>
    <String, dynamic>{
      'category': _$PresignUploadDtoCategoryEnumEnumMap[instance.category]!,
      'title': instance.title,
      'mimeType': instance.mimeType,
      'sizeBytes': instance.sizeBytes,
      if (instance.stageId case final value?) 'stageId': value,
      if (instance.stepId case final value?) 'stepId': value,
    };

const _$PresignUploadDtoCategoryEnumEnumMap = {
  PresignUploadDtoCategoryEnum.contract: 'contract',
  PresignUploadDtoCategoryEnum.act: 'act',
  PresignUploadDtoCategoryEnum.estimate: 'estimate',
  PresignUploadDtoCategoryEnum.warranty: 'warranty',
  PresignUploadDtoCategoryEnum.photo: 'photo',
  PresignUploadDtoCategoryEnum.blueprint: 'blueprint',
  PresignUploadDtoCategoryEnum.other: 'other',
};
