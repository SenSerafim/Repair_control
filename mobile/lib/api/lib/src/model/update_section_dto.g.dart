// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_section_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateSectionDto _$UpdateSectionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateSectionDto', json, ($checkedConvert) {
      final val = UpdateSectionDto(
        title: $checkedConvert('title', (v) => v as String?),
        orderIndex: $checkedConvert('orderIndex', (v) => v as num?),
      );
      return val;
    });

Map<String, dynamic> _$UpdateSectionDtoToJson(UpdateSectionDto instance) =>
    <String, dynamic>{
      if (instance.title case final value?) 'title': value,
      if (instance.orderIndex case final value?) 'orderIndex': value,
    };
