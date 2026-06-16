//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'recovery_send_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecoverySendDto {
  /// Returns a new [RecoverySendDto] instance.
  RecoverySendDto({required this.phone});

  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final String phone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecoverySendDto && other.phone == phone;

  @override
  int get hashCode => phone.hashCode;

  factory RecoverySendDto.fromJson(Map<String, dynamic> json) =>
      _$RecoverySendDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RecoverySendDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
