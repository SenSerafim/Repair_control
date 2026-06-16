//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'set_active_role_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetActiveRoleDto {
  /// Returns a new [SetActiveRoleDto] instance.
  SetActiveRoleDto({required this.role});

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final SetActiveRoleDtoRoleEnum role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SetActiveRoleDto && other.role == role;

  @override
  int get hashCode => role.hashCode;

  factory SetActiveRoleDto.fromJson(Map<String, dynamic> json) =>
      _$SetActiveRoleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SetActiveRoleDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum SetActiveRoleDtoRoleEnum {
  @JsonValue(r'customer')
  customer(r'customer'),
  @JsonValue(r'representative')
  representative(r'representative'),
  @JsonValue(r'contractor')
  contractor(r'contractor'),
  @JsonValue(r'master')
  master(r'master');

  const SetActiveRoleDtoRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
