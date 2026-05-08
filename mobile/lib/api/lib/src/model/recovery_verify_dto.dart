//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'recovery_verify_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecoveryVerifyDto {
  /// Returns a new [RecoveryVerifyDto] instance.
  RecoveryVerifyDto({

    required  this.phone,

    required  this.code,
  });

  @JsonKey(
    
    name: r'phone',
    required: true,
    includeIfNull: false,
  )


  final String phone;



  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RecoveryVerifyDto &&
      other.phone == phone &&
      other.code == code;

    @override
    int get hashCode =>
        phone.hashCode +
        code.hashCode;

  factory RecoveryVerifyDto.fromJson(Map<String, dynamic> json) => _$RecoveryVerifyDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RecoveryVerifyDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

