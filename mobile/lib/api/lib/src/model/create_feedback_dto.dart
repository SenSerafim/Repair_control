//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_feedback_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateFeedbackDto {
  /// Returns a new [CreateFeedbackDto] instance.
  CreateFeedbackDto({required this.text, this.attachmentKeys});

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @JsonKey(name: r'attachmentKeys', required: false, includeIfNull: false)
  final List<String>? attachmentKeys;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateFeedbackDto &&
          other.text == text &&
          other.attachmentKeys == attachmentKeys;

  @override
  int get hashCode => text.hashCode + attachmentKeys.hashCode;

  factory CreateFeedbackDto.fromJson(Map<String, dynamic> json) =>
      _$CreateFeedbackDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateFeedbackDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
