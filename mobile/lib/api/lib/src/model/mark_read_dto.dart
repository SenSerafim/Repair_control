//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'mark_read_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MarkReadDto {
  /// Returns a new [MarkReadDto] instance.
  MarkReadDto({required this.messageId});

  @JsonKey(name: r'messageId', required: true, includeIfNull: false)
  final String messageId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkReadDto && other.messageId == messageId;

  @override
  int get hashCode => messageId.hashCode;

  factory MarkReadDto.fromJson(Map<String, dynamic> json) =>
      _$MarkReadDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MarkReadDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
