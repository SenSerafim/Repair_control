// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'force_archive_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForceArchiveDto _$ForceArchiveDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ForceArchiveDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason']);
      final val = ForceArchiveDto(
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ForceArchiveDtoToJson(ForceArchiveDto instance) =>
    <String, dynamic>{'reason': instance.reason};
