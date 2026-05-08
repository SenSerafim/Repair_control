// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch_feedback_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchFeedbackDto _$PatchFeedbackDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PatchFeedbackDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['status']);
      final val = PatchFeedbackDto(
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$PatchFeedbackDtoStatusEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PatchFeedbackDtoToJson(PatchFeedbackDto instance) =>
    <String, dynamic>{
      'status': _$PatchFeedbackDtoStatusEnumEnumMap[instance.status]!,
    };

const _$PatchFeedbackDtoStatusEnumEnumMap = {
  PatchFeedbackDtoStatusEnum.new_: 'new',
  PatchFeedbackDtoStatusEnum.read: 'read',
  PatchFeedbackDtoStatusEnum.archived: 'archived',
};
