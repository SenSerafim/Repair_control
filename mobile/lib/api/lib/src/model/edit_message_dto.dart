//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'edit_message_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EditMessageDto {
  /// Returns a new [EditMessageDto] instance.
  EditMessageDto({required this.text});

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EditMessageDto && other.text == text;

  @override
  int get hashCode => text.hashCode;

  factory EditMessageDto.fromJson(Map<String, dynamic> json) =>
      _$EditMessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EditMessageDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
