//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'presign_upload_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PresignUploadDto {
  /// Returns a new [PresignUploadDto] instance.
  PresignUploadDto({
    required this.category,

    required this.title,

    required this.mimeType,

    required this.sizeBytes,

    this.stageId,

    this.stepId,
  });

  @JsonKey(name: r'category', required: true, includeIfNull: false)
  final PresignUploadDtoCategoryEnum category;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'mimeType', required: true, includeIfNull: false)
  final String mimeType;

  @JsonKey(name: r'sizeBytes', required: true, includeIfNull: false)
  final num sizeBytes;

  @JsonKey(name: r'stageId', required: false, includeIfNull: false)
  final String? stageId;

  @JsonKey(name: r'stepId', required: false, includeIfNull: false)
  final String? stepId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresignUploadDto &&
          other.category == category &&
          other.title == title &&
          other.mimeType == mimeType &&
          other.sizeBytes == sizeBytes &&
          other.stageId == stageId &&
          other.stepId == stepId;

  @override
  int get hashCode =>
      category.hashCode +
      title.hashCode +
      mimeType.hashCode +
      sizeBytes.hashCode +
      stageId.hashCode +
      stepId.hashCode;

  factory PresignUploadDto.fromJson(Map<String, dynamic> json) =>
      _$PresignUploadDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PresignUploadDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PresignUploadDtoCategoryEnum {
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

  const PresignUploadDtoCategoryEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
