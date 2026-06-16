//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'patch_document_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PatchDocumentDto {
  /// Returns a new [PatchDocumentDto] instance.
  PatchDocumentDto({this.title, this.category, this.stageId, this.stepId});

  @JsonKey(name: r'title', required: false, includeIfNull: false)
  final String? title;

  @JsonKey(name: r'category', required: false, includeIfNull: false)
  final PatchDocumentDtoCategoryEnum? category;

  @JsonKey(name: r'stageId', required: false, includeIfNull: false)
  final String? stageId;

  @JsonKey(name: r'stepId', required: false, includeIfNull: false)
  final String? stepId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatchDocumentDto &&
          other.title == title &&
          other.category == category &&
          other.stageId == stageId &&
          other.stepId == stepId;

  @override
  int get hashCode =>
      title.hashCode + category.hashCode + stageId.hashCode + stepId.hashCode;

  factory PatchDocumentDto.fromJson(Map<String, dynamic> json) =>
      _$PatchDocumentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PatchDocumentDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PatchDocumentDtoCategoryEnum {
  @JsonValue(r'contract')
  contract(r'contract'),
  @JsonValue(r'act')
  act(r'act'),
  @JsonValue(r'estimate')
  estimate(r'estimate'),
  @JsonValue(r'warranty')
  warranty(r'warranty'),
  @JsonValue(r'photo')
  photo(r'photo'),
  @JsonValue(r'blueprint')
  blueprint(r'blueprint'),
  @JsonValue(r'other')
  other(r'other');

  const PatchDocumentDtoCategoryEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
