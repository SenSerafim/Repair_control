// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_section_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateSectionDto _$CreateSectionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateSectionDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['title', 'orderIndex']);
      final val = CreateSectionDto(
        title: $checkedConvert('title', (v) => v as String),
        orderIndex: $checkedConvert('orderIndex', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$CreateSectionDtoToJson(CreateSectionDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'orderIndex': instance.orderIndex,
    };
