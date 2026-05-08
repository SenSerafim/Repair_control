// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_step_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateStepDto _$UpdateStepDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateStepDto', json, ($checkedConvert) {
      final val = UpdateStepDto(
        title: $checkedConvert('title', (v) => v as String?),
        price: $checkedConvert('price', (v) => v as num?),
        description: $checkedConvert('description', (v) => v as String?),
        assigneeIds: $checkedConvert(
          'assigneeIds',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$UpdateStepDtoToJson(UpdateStepDto instance) =>
    <String, dynamic>{
      if (instance.title case final value?) 'title': value,
      if (instance.price case final value?) 'price': value,
      if (instance.description case final value?) 'description': value,
      if (instance.assigneeIds case final value?) 'assigneeIds': value,
    };
