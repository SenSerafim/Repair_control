//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'register_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RegisterDto {
  /// Returns a new [RegisterDto] instance.
  RegisterDto({

    required  this.phone,

    required  this.password,

    required  this.firstName,

    required  this.lastName,

    required  this.role,

     this.language,
  });

  @JsonKey(
    
    name: r'phone',
    required: true,
    includeIfNull: false,
  )


  final String phone;



  @JsonKey(
    
    name: r'password',
    required: true,
    includeIfNull: false,
  )


  final String password;



  @JsonKey(
    
    name: r'firstName',
    required: true,
    includeIfNull: false,
  )


  final String firstName;



  @JsonKey(
    
    name: r'lastName',
    required: true,
    includeIfNull: false,
  )


  final String lastName;



  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final RegisterDtoRoleEnum role;



  @JsonKey(
    
    name: r'language',
    required: false,
    includeIfNull: false,
  )


  final String? language;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RegisterDto &&
      other.phone == phone &&
      other.password == password &&
      other.firstName == firstName &&
      other.lastName == lastName &&
      other.role == role &&
      other.language == language;

    @override
    int get hashCode =>
        phone.hashCode +
        password.hashCode +
        firstName.hashCode +
        lastName.hashCode +
        role.hashCode +
        language.hashCode;

  factory RegisterDto.fromJson(Map<String, dynamic> json) => _$RegisterDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum RegisterDtoRoleEnum {
@JsonValue(r'customer')
customer(r'customer'),
@JsonValue(r'representative')
representative(r'representative'),
@JsonValue(r'contractor')
contractor(r'contractor'),
@JsonValue(r'master')
master(r'master');

const RegisterDtoRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


