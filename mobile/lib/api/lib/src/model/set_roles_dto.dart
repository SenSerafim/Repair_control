//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'set_roles_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetRolesDto {
  /// Returns a new [SetRolesDto] instance.
  SetRolesDto({required this.roles});

  @JsonKey(name: r'roles', required: true, includeIfNull: false)
  final List<SetRolesDtoRolesEnum> roles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SetRolesDto && other.roles == roles;

  @override
  int get hashCode => roles.hashCode;

  factory SetRolesDto.fromJson(Map<String, dynamic> json) =>
      _$SetRolesDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SetRolesDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum BroadcastFilterDtoRolesEnum {
  @JsonValue(r'customer')
  customer(r'customer'),
  @JsonValue(r'representative')
  representative(r'representative'),
  @JsonValue(r'contractor')
  contractor(r'contractor'),
  @JsonValue(r'master')
  master(r'master'),
  @JsonValue(r'admin')
  admin(r'admin');

  const BroadcastFilterDtoRolesEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
