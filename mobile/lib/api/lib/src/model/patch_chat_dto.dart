//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'patch_chat_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PatchChatDto {
  /// Returns a new [PatchChatDto] instance.
  PatchChatDto({this.title, this.visibleToCustomer});

  @JsonKey(name: r'title', required: false, includeIfNull: false)
  final String? title;

  @JsonKey(name: r'visibleToCustomer', required: false, includeIfNull: false)
  final bool? visibleToCustomer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatchChatDto &&
          other.title == title &&
          other.visibleToCustomer == visibleToCustomer;

  @override
  int get hashCode => title.hashCode + visibleToCustomer.hashCode;

  factory PatchChatDto.fromJson(Map<String, dynamic> json) =>
      _$PatchChatDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PatchChatDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
