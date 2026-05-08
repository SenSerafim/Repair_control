//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'register_device_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RegisterDeviceDto {
  /// Returns a new [RegisterDeviceDto] instance.
  RegisterDeviceDto({

    required  this.platform,

    required  this.token,
  });

  @JsonKey(
    
    name: r'platform',
    required: true,
    includeIfNull: false,
  )


  final RegisterDeviceDtoPlatformEnum platform;



  @JsonKey(
    
    name: r'token',
    required: true,
    includeIfNull: false,
  )


  final String token;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RegisterDeviceDto &&
      other.platform == platform &&
      other.token == token;

    @override
    int get hashCode =>
        platform.hashCode +
        token.hashCode;

  factory RegisterDeviceDto.fromJson(Map<String, dynamic> json) => _$RegisterDeviceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterDeviceDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum RegisterDeviceDtoPlatformEnum {
@JsonValue(r'ios')
ios(r'ios'),
@JsonValue(r'android')
android(r'android');

const RegisterDeviceDtoPlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


