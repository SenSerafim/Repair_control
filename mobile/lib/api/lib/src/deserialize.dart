import 'package:repair_control_api/src/model/accept_legal_dto.dart';
import 'package:repair_control_api/src/model/add_member_dto.dart';
import 'package:repair_control_api/src/model/add_participant_dto.dart';
import 'package:repair_control_api/src/model/add_role_dto.dart';
import 'package:repair_control_api/src/model/add_substep_dto.dart';
import 'package:repair_control_api/src/model/answer_question_dto.dart';
import 'package:repair_control_api/src/model/ask_question_dto.dart';
import 'package:repair_control_api/src/model/ban_user_dto.dart';
import 'package:repair_control_api/src/model/broadcast_filter_dto.dart';
import 'package:repair_control_api/src/model/confirm_photo_dto.dart';
import 'package:repair_control_api/src/model/copy_project_dto.dart';
import 'package:repair_control_api/src/model/create_advance_dto.dart';
import 'package:repair_control_api/src/model/create_approval_dto.dart';
import 'package:repair_control_api/src/model/create_article_dto.dart';
import 'package:repair_control_api/src/model/create_export_dto.dart';
import 'package:repair_control_api/src/model/create_faq_item_dto.dart';
import 'package:repair_control_api/src/model/create_faq_section_dto.dart';
import 'package:repair_control_api/src/model/create_feedback_dto.dart';
import 'package:repair_control_api/src/model/create_group_chat_dto.dart';
import 'package:repair_control_api/src/model/create_legal_dto.dart';
import 'package:repair_control_api/src/model/create_material_request_dto.dart';
import 'package:repair_control_api/src/model/create_message_dto.dart';
import 'package:repair_control_api/src/model/create_note_dto.dart';
import 'package:repair_control_api/src/model/create_personal_chat_dto.dart';
import 'package:repair_control_api/src/model/create_project_dto.dart';
import 'package:repair_control_api/src/model/create_section_dto.dart';
import 'package:repair_control_api/src/model/create_self_purchase_dto.dart';
import 'package:repair_control_api/src/model/create_stage_dto.dart';
import 'package:repair_control_api/src/model/create_stage_from_template_dto.dart';
import 'package:repair_control_api/src/model/create_step_dto.dart';
import 'package:repair_control_api/src/model/create_tool_dto.dart';
import 'package:repair_control_api/src/model/decide_approval_dto.dart';
import 'package:repair_control_api/src/model/decide_self_purchase_dto.dart';
import 'package:repair_control_api/src/model/dispute_material_dto.dart';
import 'package:repair_control_api/src/model/dispute_payment_dto.dart';
import 'package:repair_control_api/src/model/distribute_dto.dart';
import 'package:repair_control_api/src/model/edit_message_dto.dart';
import 'package:repair_control_api/src/model/force_archive_dto.dart';
import 'package:repair_control_api/src/model/forward_message_dto.dart';
import 'package:repair_control_api/src/model/invite_by_phone_dto.dart';
import 'package:repair_control_api/src/model/issue_tool_dto.dart';
import 'package:repair_control_api/src/model/login_dto.dart';
import 'package:repair_control_api/src/model/logout_dto.dart';
import 'package:repair_control_api/src/model/mark_bought_dto.dart';
import 'package:repair_control_api/src/model/mark_read_dto.dart';
import 'package:repair_control_api/src/model/material_item_input_dto.dart';
import 'package:repair_control_api/src/model/patch_chat_dto.dart';
import 'package:repair_control_api/src/model/patch_document_dto.dart';
import 'package:repair_control_api/src/model/patch_feedback_dto.dart';
import 'package:repair_control_api/src/model/patch_setting_dto.dart';
import 'package:repair_control_api/src/model/pause_stage_dto.dart';
import 'package:repair_control_api/src/model/presign_photo_dto.dart';
import 'package:repair_control_api/src/model/presign_upload_dto.dart';
import 'package:repair_control_api/src/model/preview_dto.dart';
import 'package:repair_control_api/src/model/put_setting_dto.dart';
import 'package:repair_control_api/src/model/recovery_reset_dto.dart';
import 'package:repair_control_api/src/model/recovery_send_dto.dart';
import 'package:repair_control_api/src/model/recovery_verify_dto.dart';
import 'package:repair_control_api/src/model/refresh_dto.dart';
import 'package:repair_control_api/src/model/register_device_dto.dart';
import 'package:repair_control_api/src/model/register_dto.dart';
import 'package:repair_control_api/src/model/reorder_item_dto.dart';
import 'package:repair_control_api/src/model/reorder_stages_dto.dart';
import 'package:repair_control_api/src/model/reorder_step_item_dto.dart';
import 'package:repair_control_api/src/model/reorder_steps_dto.dart';
import 'package:repair_control_api/src/model/resolve_material_dto.dart';
import 'package:repair_control_api/src/model/resolve_payment_dto.dart';
import 'package:repair_control_api/src/model/resubmit_approval_dto.dart';
import 'package:repair_control_api/src/model/return_tool_dto.dart';
import 'package:repair_control_api/src/model/save_as_template_dto.dart';
import 'package:repair_control_api/src/model/send_broadcast_dto.dart';
import 'package:repair_control_api/src/model/set_active_role_dto.dart';
import 'package:repair_control_api/src/model/set_roles_dto.dart';
import 'package:repair_control_api/src/model/update_article_dto.dart';
import 'package:repair_control_api/src/model/update_faq_item_dto.dart';
import 'package:repair_control_api/src/model/update_legal_dto.dart';
import 'package:repair_control_api/src/model/update_membership_dto.dart';
import 'package:repair_control_api/src/model/update_note_dto.dart';
import 'package:repair_control_api/src/model/update_profile_dto.dart';
import 'package:repair_control_api/src/model/update_project_dto.dart';
import 'package:repair_control_api/src/model/update_section_dto.dart';
import 'package:repair_control_api/src/model/update_stage_dto.dart';
import 'package:repair_control_api/src/model/update_step_dto.dart';
import 'package:repair_control_api/src/model/update_substep_dto.dart';
import 'package:repair_control_api/src/model/update_tool_dto.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

  ReturnType deserialize<ReturnType, BaseType>(dynamic value, String targetType, {bool growable= true}) {
      switch (targetType) {
        case 'String':
          return '$value' as ReturnType;
        case 'int':
          return (value is int ? value : int.parse('$value')) as ReturnType;
        case 'bool':
          if (value is bool) {
            return value as ReturnType;
          }
          final valueString = '$value'.toLowerCase();
          return (valueString == 'true' || valueString == '1') as ReturnType;
        case 'double':
          return (value is double ? value : double.parse('$value')) as ReturnType;
        case 'AcceptLegalDto':
          return AcceptLegalDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AddMemberDto':
          return AddMemberDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AddParticipantDto':
          return AddParticipantDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AddRoleDto':
          return AddRoleDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AddSubstepDto':
          return AddSubstepDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AnswerQuestionDto':
          return AnswerQuestionDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AskQuestionDto':
          return AskQuestionDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BanUserDto':
          return BanUserDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BroadcastFilterDto':
          return BroadcastFilterDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConfirmPhotoDto':
          return ConfirmPhotoDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CopyProjectDto':
          return CopyProjectDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateAdvanceDto':
          return CreateAdvanceDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateApprovalDto':
          return CreateApprovalDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateArticleDto':
          return CreateArticleDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateExportDto':
          return CreateExportDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateFaqItemDto':
          return CreateFaqItemDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateFaqSectionDto':
          return CreateFaqSectionDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateFeedbackDto':
          return CreateFeedbackDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateGroupChatDto':
          return CreateGroupChatDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateLegalDto':
          return CreateLegalDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateMaterialRequestDto':
          return CreateMaterialRequestDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateMessageDto':
          return CreateMessageDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateNoteDto':
          return CreateNoteDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreatePersonalChatDto':
          return CreatePersonalChatDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateProjectDto':
          return CreateProjectDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateSectionDto':
          return CreateSectionDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateSelfPurchaseDto':
          return CreateSelfPurchaseDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateStageDto':
          return CreateStageDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateStageFromTemplateDto':
          return CreateStageFromTemplateDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateStepDto':
          return CreateStepDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateToolDto':
          return CreateToolDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DecideApprovalDto':
          return DecideApprovalDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DecideSelfPurchaseDto':
          return DecideSelfPurchaseDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DisputeMaterialDto':
          return DisputeMaterialDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DisputePaymentDto':
          return DisputePaymentDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DistributeDto':
          return DistributeDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EditMessageDto':
          return EditMessageDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ForceArchiveDto':
          return ForceArchiveDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ForwardMessageDto':
          return ForwardMessageDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InviteByPhoneDto':
          return InviteByPhoneDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IssueToolDto':
          return IssueToolDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LoginDto':
          return LoginDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LogoutDto':
          return LogoutDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MarkBoughtDto':
          return MarkBoughtDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MarkReadDto':
          return MarkReadDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MaterialItemInputDto':
          return MaterialItemInputDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PatchChatDto':
          return PatchChatDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PatchDocumentDto':
          return PatchDocumentDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PatchFeedbackDto':
          return PatchFeedbackDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PatchSettingDto':
          return PatchSettingDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PauseStageDto':
          return PauseStageDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PresignPhotoDto':
          return PresignPhotoDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PresignUploadDto':
          return PresignUploadDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PreviewDto':
          return PreviewDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PutSettingDto':
          return PutSettingDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RecoveryResetDto':
          return RecoveryResetDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RecoverySendDto':
          return RecoverySendDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RecoveryVerifyDto':
          return RecoveryVerifyDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RefreshDto':
          return RefreshDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RegisterDeviceDto':
          return RegisterDeviceDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RegisterDto':
          return RegisterDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReorderItemDto':
          return ReorderItemDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReorderStagesDto':
          return ReorderStagesDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReorderStepItemDto':
          return ReorderStepItemDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReorderStepsDto':
          return ReorderStepsDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ResolveMaterialDto':
          return ResolveMaterialDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ResolvePaymentDto':
          return ResolvePaymentDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ResubmitApprovalDto':
          return ResubmitApprovalDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReturnToolDto':
          return ReturnToolDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SaveAsTemplateDto':
          return SaveAsTemplateDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SendBroadcastDto':
          return SendBroadcastDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetActiveRoleDto':
          return SetActiveRoleDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetRolesDto':
          return SetRolesDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateArticleDto':
          return UpdateArticleDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateFaqItemDto':
          return UpdateFaqItemDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateLegalDto':
          return UpdateLegalDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateMembershipDto':
          return UpdateMembershipDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateNoteDto':
          return UpdateNoteDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateProfileDto':
          return UpdateProfileDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateProjectDto':
          return UpdateProjectDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateSectionDto':
          return UpdateSectionDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateStageDto':
          return UpdateStageDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateStepDto':
          return UpdateStepDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateSubstepDto':
          return UpdateSubstepDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateToolDto':
          return UpdateToolDto.fromJson(value as Map<String, dynamic>) as ReturnType;
        default:
          RegExpMatch? match;

          if (value is List && (match = _regList.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toList(growable: growable) as ReturnType;
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toSet() as ReturnType;
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
            targetType = match![1]!.trim(); // ignore: parameter_assignments
            return Map<String, BaseType>.fromIterables(
              value.keys as Iterable<String>,
              value.values.map((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable)),
            ) as ReturnType;
          }
          break;
    }
    throw Exception('Cannot deserialize');
  }