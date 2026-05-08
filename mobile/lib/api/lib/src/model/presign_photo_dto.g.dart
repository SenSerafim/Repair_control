// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presign_photo_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresignPhotoDto _$PresignPhotoDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PresignPhotoDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['mime', 'size']);
      final val = PresignPhotoDto(
        mime: $checkedConvert('mime', (v) => v as String),
        size: $checkedConvert('size', (v) => v as num),
        originalName: $checkedConvert('originalName', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$PresignPhotoDtoToJson(PresignPhotoDto instance) =>
    <String, dynamic>{
      'mime': instance.mime,
      'size': instance.size,
      if (instance.originalName case final value?) 'originalName': value,
    };
