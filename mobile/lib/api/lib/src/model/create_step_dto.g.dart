// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_step_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateStepDto _$CreateStepDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateStepDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['title']);
      final val = CreateStepDto(
        title: $checkedConvert('title', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) =>
              $enumDecodeNullable(_$CreateStepDtoTypeEnumEnumMap, v) ??
              'regular',
        ),
        price: $checkedConvert('price', (v) => v as num?),
        description: $checkedConvert('description', (v) => v as String?),
        orderIndex: $checkedConvert('orderIndex', (v) => v as num?),
        assigneeIds: $checkedConvert(
          'assigneeIds',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CreateStepDtoToJson(CreateStepDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      if (_$CreateStepDtoTypeEnumEnumMap[instance.type] case final value?)
        'type': value,
      if (instance.price case final value?) 'price': value,
      if (instance.description case final value?) 'description': value,
      if (instance.orderIndex case final value?) 'orderIndex': value,
      if (instance.assigneeIds case final value?) 'assigneeIds': value,
    };

const _$CreateStepDtoTypeEnumEnumMap = {
  CreateStepDtoTypeEnum.regular: 'regular',
  CreateStepDtoTypeEnum.extra: 'extra',
};
