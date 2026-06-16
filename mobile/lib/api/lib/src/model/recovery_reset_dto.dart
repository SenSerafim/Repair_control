//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'recovery_reset_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecoveryResetDto {
  /// Returns a new [RecoveryResetDto] instance.
  RecoveryResetDto({
    required this.phone,

    required this.code,

    required this.newPassword,
  });

  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final String phone;

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'newPassword', required: true, includeIfNull: false)
  final String newPassword;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecoveryResetDto &&
          other.phone == phone &&
          other.code == code &&
          other.newPassword == newPassword;

  @override
  int get hashCode => phone.hashCode + code.hashCode + newPassword.hashCode;

  factory RecoveryResetDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryResetDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RecoveryResetDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
