// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_stage_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateStageDto _$UpdateStageDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateStageDto', json, ($checkedConvert) {
      final val = UpdateStageDto(
        title: $checkedConvert('title', (v) => v as String?),
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

Map<String, dynamic> _$UpdateStageDtoToJson(UpdateStageDto instance) =>
    <String, dynamic>{
      if (instance.title case final value?) 'title': value,
      if (instance.plannedStart case final value?) 'plannedStart': value,
      if (instance.plannedEnd case final value?) 'plannedEnd': value,
      if (instance.workBudget case final value?) 'workBudget': value,
      if (instance.materialsBudget case final value?) 'materialsBudget': value,
      if (instance.foremanIds case final value?) 'foremanIds': value,
    };
