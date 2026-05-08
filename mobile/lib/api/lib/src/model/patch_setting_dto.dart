//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'patch_setting_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PatchSettingDto {
  /// Returns a new [PatchSettingDto] instance.
  PatchSettingDto({

    required  this.kind,

    required  this.pushEnabled,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final PatchSettingDtoKindEnum kind;



  @JsonKey(
    
    name: r'pushEnabled',
    required: true,
    includeIfNull: false,
  )


  final bool pushEnabled;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PatchSettingDto &&
      other.kind == kind &&
      other.pushEnabled == pushEnabled;

    @override
    int get hashCode =>
        kind.hashCode +
        pushEnabled.hashCode;

  factory PatchSettingDto.fromJson(Map<String, dynamic> json) => _$PatchSettingDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PatchSettingDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PatchSettingDtoKindEnum {
@JsonValue(r'approval_requested')
approvalRequested(r'approval_requested'),
@JsonValue(r'approval_approved')
approvalApproved(r'approval_approved'),
@JsonValue(r'approval_rejected')
approvalRejected(r'approval_rejected'),
@JsonValue(r'payment_created')
paymentCreated(r'payment_created'),
@JsonValue(r'payment_confirmed')
paymentConfirmed(r'payment_confirmed'),
@JsonValue(r'payment_disputed')
paymentDisputed(r'payment_disputed'),
@JsonValue(r'payment_resolved')
paymentResolved(r'payment_resolved'),
@JsonValue(r'stage_rejected_by_customer')
stageRejectedByCustomer(r'stage_rejected_by_customer'),
@JsonValue(r'stage_overdue')
stageOverdue(r'stage_overdue'),
@JsonValue(r'stage_deadline_exceeds_project')
stageDeadlineExceedsProject(r'stage_deadline_exceeds_project'),
@JsonValue(r'material_request_created')
materialRequestCreated(r'material_request_created'),
@JsonValue(r'material_delivered')
materialDelivered(r'material_delivered'),
@JsonValue(r'material_disputed')
materialDisputed(r'material_disputed'),
@JsonValue(r'selfpurchase_created')
selfpurchaseCreated(r'selfpurchase_created'),
@JsonValue(r'tool_issued')
toolIssued(r'tool_issued'),
@JsonValue(r'export_completed')
exportCompleted(r'export_completed'),
@JsonValue(r'export_failed')
exportFailed(r'export_failed'),
@JsonValue(r'chat_message_new')
chatMessageNew(r'chat_message_new'),
@JsonValue(r'step_completed')
stepCompleted(r'step_completed'),
@JsonValue(r'stage_completed')
stageCompleted(r'stage_completed'),
@JsonValue(r'stage_paused')
stagePaused(r'stage_paused'),
@JsonValue(r'note_created_for_me')
noteCreatedForMe(r'note_created_for_me'),
@JsonValue(r'question_asked')
questionAsked(r'question_asked'),
@JsonValue(r'project_archived')
projectArchived(r'project_archived'),
@JsonValue(r'membership_added')
membershipAdded(r'membership_added');

const PatchSettingDtoKindEnum(this.value);

final String value;

@override
String toString() => value;
}


