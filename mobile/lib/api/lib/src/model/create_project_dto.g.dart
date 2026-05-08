// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_project_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateProjectDto _$CreateProjectDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateProjectDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['title']);
      final val = CreateProjectDto(
        title: $checkedConvert('title', (v) => v as String),
        address: $checkedConvert('address', (v) => v as String?),
        plannedStart: $checkedConvert('plannedStart', (v) => v as String?),
        plannedEnd: $checkedConvert('plannedEnd', (v) => v as String?),
        workBudget: $checkedConvert('workBudget', (v) => (v as num?)?.toInt()),
        materialsBudget: $checkedConvert(
          'materialsBudget',
          (v) => (v as num?)?.toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CreateProjectDtoToJson(CreateProjectDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      if (instance.address case final value?) 'address': value,
      if (instance.plannedStart case final value?) 'plannedStart': value,
      if (instance.plannedEnd case final value?) 'plannedEnd': value,
      if (instance.workBudget case final value?) 'workBudget': value,
      if (instance.materialsBudget case final value?) 'materialsBudget': value,
    };
