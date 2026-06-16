//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'logout_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LogoutDto {
  /// Returns a new [LogoutDto] instance.
  LogoutDto({required this.refreshToken});

  @JsonKey(name: r'refreshToken', required: true, includeIfNull: false)
  final String refreshToken;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogoutDto && other.refreshToken == refreshToken;

  @override
  int get hashCode => refreshToken.hashCode;

  factory LogoutDto.fromJson(Map<String, dynamic> json) =>
      _$LogoutDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LogoutDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
