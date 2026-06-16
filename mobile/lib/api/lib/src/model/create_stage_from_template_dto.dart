//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_stage_from_template_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateStageFromTemplateDto {
  /// Returns a new [CreateStageFromTemplateDto] instance.
  CreateStageFromTemplateDto({
    required this.projectId,

    this.plannedStart,

    this.plannedEnd,
  });

  @JsonKey(name: r'projectId', required: true, includeIfNull: false)
  final String projectId;

  @JsonKey(name: r'plannedStart', required: false, includeIfNull: false)
  final String? plannedStart;

  @JsonKey(name: r'plannedEnd', required: false, includeIfNull: false)
  final String? plannedEnd;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateStageFromTemplateDto &&
          other.projectId == projectId &&
          other.plannedStart == plannedStart &&
          other.plannedEnd == plannedEnd;

  @override
  int get hashCode =>
      projectId.hashCode + plannedStart.hashCode + plannedEnd.hashCode;

  factory CreateStageFromTemplateDto.fromJson(Map<String, dynamic> json) =>
      _$CreateStageFromTemplateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateStageFromTemplateDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
