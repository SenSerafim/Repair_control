//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_group_chat_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateGroupChatDto {
  /// Returns a new [CreateGroupChatDto] instance.
  CreateGroupChatDto({required this.title, required this.participantUserIds});

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'participantUserIds', required: true, includeIfNull: false)
  final List<String> participantUserIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateGroupChatDto &&
          other.title == title &&
          other.participantUserIds == participantUserIds;

  @override
  int get hashCode => title.hashCode + participantUserIds.hashCode;

  factory CreateGroupChatDto.fromJson(Map<String, dynamic> json) =>
      _$CreateGroupChatDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateGroupChatDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
