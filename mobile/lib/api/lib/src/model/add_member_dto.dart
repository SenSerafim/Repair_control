//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'add_member_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddMemberDto {
  /// Returns a new [AddMemberDto] instance.
  AddMemberDto({
    required this.userId,

    required this.role,

    this.permissions,

    this.stageIds,
  });

  @JsonKey(name: r'userId', required: true, includeIfNull: false)
  final String userId;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final AddMemberDtoRoleEnum role;

  @JsonKey(name: r'permissions', required: false, includeIfNull: false)
  final Object? permissions;

  @JsonKey(name: r'stageIds', required: false, includeIfNull: false)
  final List<String>? stageIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddMemberDto &&
          other.userId == userId &&
          other.role == role &&
          other.permissions == permissions &&
          other.stageIds == stageIds;

  @override
  int get hashCode =>
      userId.hashCode +
      role.hashCode +
      permissions.hashCode +
      stageIds.hashCode;

  factory AddMemberDto.fromJson(Map<String, dynamic> json) =>
      _$AddMemberDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AddMemberDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AddMemberDtoRoleEnum {
  @JsonValue(r'customer')
  customer(r'customer'),
  @JsonValue(r'representative')
  representative(r'representative'),
  @JsonValue(r'foreman')
  foreman(r'foreman'),
  @JsonValue(r'master')
  master(r'master');

  const AddMemberDtoRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
