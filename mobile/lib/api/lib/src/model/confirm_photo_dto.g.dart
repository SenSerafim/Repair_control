// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirm_photo_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfirmPhotoDto _$ConfirmPhotoDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ConfirmPhotoDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['fileKey', 'mimeType', 'sizeBytes'],
      );
      final val = ConfirmPhotoDto(
        fileKey: $checkedConvert('fileKey', (v) => v as String),
        mimeType: $checkedConvert('mimeType', (v) => v as String),
        sizeBytes: $checkedConvert('sizeBytes', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$ConfirmPhotoDtoToJson(ConfirmPhotoDto instance) =>
    <String, dynamic>{
      'fileKey': instance.fileKey,
      'mimeType': instance.mimeType,
      'sizeBytes': instance.sizeBytes,
    };
