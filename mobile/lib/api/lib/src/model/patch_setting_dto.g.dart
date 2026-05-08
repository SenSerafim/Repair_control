// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch_setting_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchSettingDto _$PatchSettingDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PatchSettingDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['kind', 'pushEnabled']);
      final val = PatchSettingDto(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$PatchSettingDtoKindEnumEnumMap, v),
        ),
        pushEnabled: $checkedConvert('pushEnabled', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$PatchSettingDtoToJson(PatchSettingDto instance) =>
    <String, dynamic>{
      'kind': _$PatchSettingDtoKindEnumEnumMap[instance.kind]!,
      'pushEnabled': instance.pushEnabled,
    };

const _$PatchSettingDtoKindEnumEnumMap = {
  PatchSettingDtoKindEnum.approvalRequested: 'approval_requested',
  PatchSettingDtoKindEnum.approvalApproved: 'approval_approved',
  PatchSettingDtoKindEnum.approvalRejected: 'approval_rejected',
  PatchSettingDtoKindEnum.paymentCreated: 'payment_created',
  PatchSettingDtoKindEnum.paymentConfirmed: 'payment_confirmed',
  PatchSettingDtoKindEnum.paymentDisputed: 'payment_disputed',
  PatchSettingDtoKindEnum.paymentResolved: 'payment_resolved',
  PatchSettingDtoKindEnum.stageRejectedByCustomer: 'stage_rejected_by_customer',
  PatchSettingDtoKindEnum.stageOverdue: 'stage_overdue',
  PatchSettingDtoKindEnum.stageDeadlineExceedsProject:
      'stage_deadline_exceeds_project',
  PatchSettingDtoKindEnum.materialRequestCreated: 'material_request_created',
  PatchSettingDtoKindEnum.materialDelivered: 'material_delivered',
  PatchSettingDtoKindEnum.materialDisputed: 'material_disputed',
  PatchSettingDtoKindEnum.selfpurchaseCreated: 'selfpurchase_created',
  PatchSettingDtoKindEnum.toolIssued: 'tool_issued',
  PatchSettingDtoKindEnum.exportCompleted: 'export_completed',
  PatchSettingDtoKindEnum.exportFailed: 'export_failed',
  PatchSettingDtoKindEnum.chatMessageNew: 'chat_message_new',
  PatchSettingDtoKindEnum.stepCompleted: 'step_completed',
  PatchSettingDtoKindEnum.stageCompleted: 'stage_completed',
  PatchSettingDtoKindEnum.stagePaused: 'stage_paused',
  PatchSettingDtoKindEnum.noteCreatedForMe: 'note_created_for_me',
  PatchSettingDtoKindEnum.questionAsked: 'question_asked',
  PatchSettingDtoKindEnum.projectArchived: 'project_archived',
  PatchSettingDtoKindEnum.membershipAdded: 'membership_added',
};
