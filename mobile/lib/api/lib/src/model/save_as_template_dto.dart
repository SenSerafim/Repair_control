//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'save_as_template_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SaveAsTemplateDto {
  /// Returns a new [SaveAsTemplateDto] instance.
  SaveAsTemplateDto({required this.title});

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveAsTemplateDto && other.title == title;

  @override
  int get hashCode => title.hashCode;

  factory SaveAsTemplateDto.fromJson(Map<String, dynamic> json) =>
      _$SaveAsTemplateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SaveAsTemplateDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
