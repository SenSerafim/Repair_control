// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_substep_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddSubstepDto _$AddSubstepDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AddSubstepDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['text']);
      final val = AddSubstepDto(
        text: $checkedConvert('text', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AddSubstepDtoToJson(AddSubstepDto instance) =>
    <String, dynamic>{'text': instance.text};
