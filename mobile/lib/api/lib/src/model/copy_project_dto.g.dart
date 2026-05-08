// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'copy_project_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CopyProjectDto _$CopyProjectDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CopyProjectDto', json, ($checkedConvert) {
      final val = CopyProjectDto(
        newTitle: $checkedConvert('newTitle', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CopyProjectDtoToJson(CopyProjectDto instance) =>
    <String, dynamic>{
      if (instance.newTitle case final value?) 'newTitle': value,
    };
