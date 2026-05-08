// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_approval_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateApprovalDto _$CreateApprovalDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateApprovalDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['scope', 'addresseeId']);
      final val = CreateApprovalDto(
        scope: $checkedConvert(
          'scope',
          (v) => $enumDecode(_$CreateApprovalDtoScopeEnumEnumMap, v),
        ),
        stageId: $checkedConvert('stageId', (v) => v as String?),
        stepId: $checkedConvert('stepId', (v) => v as String?),
        addresseeId: $checkedConvert('addresseeId', (v) => v as String),
        payload: $checkedConvert('payload', (v) => v),
        attachmentKeys: $checkedConvert(
          'attachmentKeys',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CreateApprovalDtoToJson(CreateApprovalDto instance) =>
    <String, dynamic>{
      'scope': _$CreateApprovalDtoScopeEnumEnumMap[instance.scope]!,
      if (instance.stageId case final value?) 'stageId': value,
      if (instance.stepId case final value?) 'stepId': value,
      'addresseeId': instance.addresseeId,
      if (instance.payload case final value?) 'payload': value,
      if (instance.attachmentKeys case final value?) 'attachmentKeys': value,
    };

const _$CreateApprovalDtoScopeEnumEnumMap = {
  CreateApprovalDtoScopeEnum.plan: 'plan',
  CreateApprovalDtoScopeEnum.step: 'step',
  CreateApprovalDtoScopeEnum.extraWork: 'extra_work',
  CreateApprovalDtoScopeEnum.deadlineChange: 'deadline_change',
  CreateApprovalDtoScopeEnum.stageAccept: 'stage_accept',
};
