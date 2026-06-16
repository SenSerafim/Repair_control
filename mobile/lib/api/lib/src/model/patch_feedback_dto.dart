//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'patch_feedback_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PatchFeedbackDto {
  /// Returns a new [PatchFeedbackDto] instance.
  PatchFeedbackDto({required this.status});

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final PatchFeedbackDtoStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatchFeedbackDto && other.status == status;

  @override
  int get hashCode => status.hashCode;

  factory PatchFeedbackDto.fromJson(Map<String, dynamic> json) =>
      _$PatchFeedbackDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PatchFeedbackDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PatchFeedbackDtoStatusEnum {
  @JsonValue(r'new')
  new_(r'new'),
  @JsonValue(r'read')
  read(r'read'),
  @JsonValue(r'archived')
  archived(r'archived');

  const PatchFeedbackDtoStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
