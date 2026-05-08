// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pause_stage_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PauseStageDto _$PauseStageDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PauseStageDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason']);
      final val = PauseStageDto(
        reason: $checkedConvert(
          'reason',
          (v) => $enumDecode(_$PauseStageDtoReasonEnumEnumMap, v),
        ),
        comment: $checkedConvert('comment', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$PauseStageDtoToJson(PauseStageDto instance) =>
    <String, dynamic>{
      'reason': _$PauseStageDtoReasonEnumEnumMap[instance.reason]!,
      if (instance.comment case final value?) 'comment': value,
    };

const _$PauseStageDtoReasonEnumEnumMap = {
  PauseStageDtoReasonEnum.materials: 'materials',
  PauseStageDtoReasonEnum.approval: 'approval',
  PauseStageDtoReasonEnum.forceMajeure: 'force_majeure',
  PauseStageDtoReasonEnum.other: 'other',
};
