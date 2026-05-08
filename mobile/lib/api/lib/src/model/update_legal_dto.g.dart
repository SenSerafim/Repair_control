// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_legal_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateLegalDto _$UpdateLegalDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateLegalDto', json, ($checkedConvert) {
      final val = UpdateLegalDto(
        title: $checkedConvert('title', (v) => v as String?),
        bodyMd: $checkedConvert('bodyMd', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$UpdateLegalDtoToJson(UpdateLegalDto instance) =>
    <String, dynamic>{
      if (instance.title case final value?) 'title': value,
      if (instance.bodyMd case final value?) 'bodyMd': value,
    };
