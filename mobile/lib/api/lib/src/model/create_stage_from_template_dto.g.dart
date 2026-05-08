// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_stage_from_template_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateStageFromTemplateDto _$CreateStageFromTemplateDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateStageFromTemplateDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['projectId']);
  final val = CreateStageFromTemplateDto(
    projectId: $checkedConvert('projectId', (v) => v as String),
    plannedStart: $checkedConvert('plannedStart', (v) => v as String?),
    plannedEnd: $checkedConvert('plannedEnd', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$CreateStageFromTemplateDtoToJson(
  CreateStageFromTemplateDto instance,
) => <String, dynamic>{
  'projectId': instance.projectId,
  if (instance.plannedStart case final value?) 'plannedStart': value,
  if (instance.plannedEnd case final value?) 'plannedEnd': value,
};
