// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_stage_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateStageDto _$CreateStageDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateStageDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['title']);
      final val = CreateStageDto(
        title: $checkedConvert('title', (v) => v as String),
        orderIndex: $checkedConvert('orderIndex', (v) => v as num?),
        plannedStart: $checkedConvert('plannedStart', (v) => v as String?),
        plannedEnd: $checkedConvert('plannedEnd', (v) => v as String?),
        workBudget: $checkedConvert('workBudget', (v) => (v as num?)?.toInt()),
        materialsBudget: $checkedConvert(
          'materialsBudget',
          (v) => (v as num?)?.toInt(),
        ),
        foremanIds: $checkedConvert(
          'foremanIds',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CreateStageDtoToJson(CreateStageDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      if (instance.orderIndex case final value?) 'orderIndex': value,
      if (instance.plannedStart case final value?) 'plannedStart': value,
      if (instance.plannedEnd case final value?) 'plannedEnd': value,
      if (instance.workBudget case final value?) 'workBudget': value,
      if (instance.materialsBudget case final value?) 'materialsBudget': value,
      if (instance.foremanIds case final value?) 'foremanIds': value,
    };
