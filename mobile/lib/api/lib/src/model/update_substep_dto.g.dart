// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_substep_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateSubstepDto _$UpdateSubstepDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateSubstepDto', json, ($checkedConvert) {
      final val = UpdateSubstepDto(
        text: $checkedConvert('text', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$UpdateSubstepDtoToJson(UpdateSubstepDto instance) =>
    <String, dynamic>{if (instance.text case final value?) 'text': value};
