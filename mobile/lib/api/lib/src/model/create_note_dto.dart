//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_note_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateNoteDto {
  /// Returns a new [CreateNoteDto] instance.
  CreateNoteDto({
    required this.scope,

    required this.text,

    this.addresseeId,

    this.stageId,
  });

  @JsonKey(name: r'scope', required: true, includeIfNull: false)
  final CreateNoteDtoScopeEnum scope;

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @JsonKey(name: r'addresseeId', required: false, includeIfNull: false)
  final String? addresseeId;

  @JsonKey(name: r'stageId', required: false, includeIfNull: false)
  final String? stageId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateNoteDto &&
          other.scope == scope &&
          other.text == text &&
          other.addresseeId == addresseeId &&
          other.stageId == stageId;

  @override
  int get hashCode =>
      scope.hashCode + text.hashCode + addresseeId.hashCode + stageId.hashCode;

  factory CreateNoteDto.fromJson(Map<String, dynamic> json) =>
      _$CreateNoteDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateNoteDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CreateNoteDtoScopeEnum {
  @JsonValue(r'personal')
  personal(r'personal'),
  @JsonValue(r'for_me')
  forMe(r'for_me'),
  @JsonValue(r'stage')
  stage(r'stage');

  const CreateNoteDtoScopeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
