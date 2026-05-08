//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'invite_by_phone_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InviteByPhoneDto {
  /// Returns a new [InviteByPhoneDto] instance.
  InviteByPhoneDto({

    required  this.phone,

    required  this.role,
  });

  @JsonKey(
    
    name: r'phone',
    required: true,
    includeIfNull: false,
  )


  final String phone;



  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final InviteByPhoneDtoRoleEnum role;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InviteByPhoneDto &&
      other.phone == phone &&
      other.role == role;

    @override
    int get hashCode =>
        phone.hashCode +
        role.hashCode;

  factory InviteByPhoneDto.fromJson(Map<String, dynamic> json) => _$InviteByPhoneDtoFromJson(json);

  Map<String, dynamic> toJson() => _$InviteByPhoneDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum InviteByPhoneDtoRoleEnum {
@JsonValue(r'customer')
customer(r'customer'),
@JsonValue(r'representative')
representative(r'representative'),
@JsonValue(r'foreman')
foreman(r'foreman'),
@JsonValue(r'master')
master(r'master');

const InviteByPhoneDtoRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


