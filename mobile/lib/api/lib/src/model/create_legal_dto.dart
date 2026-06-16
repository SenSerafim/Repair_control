//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_legal_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateLegalDto {
  /// Returns a new [CreateLegalDto] instance.
  CreateLegalDto({
    required this.kind,

    required this.title,

    required this.bodyMd,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final CreateLegalDtoKindEnum kind;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'bodyMd', required: true, includeIfNull: false)
  final String bodyMd;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateLegalDto &&
          other.kind == kind &&
          other.title == title &&
          other.bodyMd == bodyMd;

  @override
  int get hashCode => kind.hashCode + title.hashCode + bodyMd.hashCode;

  factory CreateLegalDto.fromJson(Map<String, dynamic> json) =>
      _$CreateLegalDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateLegalDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CreateLegalDtoKindEnum {
  @JsonValue(r'privacy')
  privacy(r'privacy'),
  @JsonValue(r'tos')
  tos(r'tos'),
  @JsonValue(r'data_processing_consent')
  dataProcessingConsent(r'data_processing_consent');

  const CreateLegalDtoKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
