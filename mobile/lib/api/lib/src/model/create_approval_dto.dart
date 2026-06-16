//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_approval_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateApprovalDto {
  /// Returns a new [CreateApprovalDto] instance.
  CreateApprovalDto({
    required this.scope,

    this.stageId,

    this.stepId,

    required this.addresseeId,

    this.payload,

    this.attachmentKeys,
  });

  @JsonKey(name: r'scope', required: true, includeIfNull: false)
  final CreateApprovalDtoScopeEnum scope;

  @JsonKey(name: r'stageId', required: false, includeIfNull: false)
  final String? stageId;

  @JsonKey(name: r'stepId', required: false, includeIfNull: false)
  final String? stepId;

  /// Адресат решения (foreman/customer)
  @JsonKey(name: r'addresseeId', required: true, includeIfNull: false)
  final String addresseeId;

  /// Payload scope-specific (newEnd, stages[], price, ...)
  @JsonKey(name: r'payload', required: false, includeIfNull: false)
  final Object? payload;

  @JsonKey(name: r'attachmentKeys', required: false, includeIfNull: false)
  final List<String>? attachmentKeys;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateApprovalDto &&
          other.scope == scope &&
          other.stageId == stageId &&
          other.stepId == stepId &&
          other.addresseeId == addresseeId &&
          other.payload == payload &&
          other.attachmentKeys == attachmentKeys;

  @override
  int get hashCode =>
      scope.hashCode +
      stageId.hashCode +
      stepId.hashCode +
      addresseeId.hashCode +
      payload.hashCode +
      attachmentKeys.hashCode;

  factory CreateApprovalDto.fromJson(Map<String, dynamic> json) =>
      _$CreateApprovalDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateApprovalDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CreateApprovalDtoScopeEnum {
  @JsonValue(r'plan')
  plan(r'plan'),
  @JsonValue(r'step')
  step(r'step'),
  @JsonValue(r'extra_work')
  extraWork(r'extra_work'),
  @JsonValue(r'deadline_change')
  deadlineChange(r'deadline_change'),
  @JsonValue(r'stage_accept')
  stageAccept(r'stage_accept');

  const CreateApprovalDtoScopeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
