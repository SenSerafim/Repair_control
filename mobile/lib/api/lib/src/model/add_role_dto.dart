//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'add_role_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddRoleDto {
  /// Returns a new [AddRoleDto] instance.
  AddRoleDto({

    required  this.role,
  });

  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final AddRoleDtoRoleEnum role;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AddRoleDto &&
      other.role == role;

    @override
    int get hashCode =>
        role.hashCode;

  factory AddRoleDto.fromJson(Map<String, dynamic> json) => _$AddRoleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AddRoleDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum AddRoleDtoRoleEnum {
@JsonValue(r'customer')
customer(r'customer'),
@JsonValue(r'representative')
representative(r'representative'),
@JsonValue(r'contractor')
contractor(r'contractor'),
@JsonValue(r'master')
master(r'master');

const AddRoleDtoRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


