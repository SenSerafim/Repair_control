//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'login_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LoginDto {
  /// Returns a new [LoginDto] instance.
  LoginDto({

    required  this.phone,

    required  this.password,

     this.deviceId,
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
    
    name: r'deviceId',
    required: false,
    includeIfNull: false,
  )


  final String? deviceId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LoginDto &&
      other.phone == phone &&
      other.password == password &&
      other.deviceId == deviceId;

    @override
    int get hashCode =>
        phone.hashCode +
        password.hashCode +
        deviceId.hashCode;

  factory LoginDto.fromJson(Map<String, dynamic> json) => _$LoginDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LoginDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

