// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_faq_section_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateFaqSectionDto _$CreateFaqSectionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateFaqSectionDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['title', 'orderIndex']);
      final val = CreateFaqSectionDto(
        title: $checkedConvert('title', (v) => v as String),
        orderIndex: $checkedConvert('orderIndex', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$CreateFaqSectionDtoToJson(
  CreateFaqSectionDto instance,
) => <String, dynamic>{
  'title': instance.title,
  'orderIndex': instance.orderIndex,
};
