//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'ban_user_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BanUserDto {
  /// Returns a new [BanUserDto] instance.
  BanUserDto({required this.reason});

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BanUserDto && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  factory BanUserDto.fromJson(Map<String, dynamic> json) =>
      _$BanUserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$BanUserDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
