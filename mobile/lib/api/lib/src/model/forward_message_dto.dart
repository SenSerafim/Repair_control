//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'forward_message_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ForwardMessageDto {
  /// Returns a new [ForwardMessageDto] instance.
  ForwardMessageDto({required this.toChatId});

  @JsonKey(name: r'toChatId', required: true, includeIfNull: false)
  final String toChatId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForwardMessageDto && other.toChatId == toChatId;

  @override
  int get hashCode => toChatId.hashCode;

  factory ForwardMessageDto.fromJson(Map<String, dynamic> json) =>
      _$ForwardMessageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ForwardMessageDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
