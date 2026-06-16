//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_personal_chat_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreatePersonalChatDto {
  /// Returns a new [CreatePersonalChatDto] instance.
  CreatePersonalChatDto({required this.withUserId});

  @JsonKey(name: r'withUserId', required: true, includeIfNull: false)
  final String withUserId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreatePersonalChatDto && other.withUserId == withUserId;

  @override
  int get hashCode => withUserId.hashCode;

  factory CreatePersonalChatDto.fromJson(Map<String, dynamic> json) =>
      _$CreatePersonalChatDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePersonalChatDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
