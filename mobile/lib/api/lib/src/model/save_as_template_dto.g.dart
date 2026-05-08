// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_as_template_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveAsTemplateDto _$SaveAsTemplateDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SaveAsTemplateDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['title']);
      final val = SaveAsTemplateDto(
        title: $checkedConvert('title', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SaveAsTemplateDtoToJson(SaveAsTemplateDto instance) =>
    <String, dynamic>{'title': instance.title};
