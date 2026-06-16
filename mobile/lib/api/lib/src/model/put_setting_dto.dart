//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'put_setting_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PutSettingDto {
  /// Returns a new [PutSettingDto] instance.
  PutSettingDto({required this.key, required this.value});

  @JsonKey(name: r'key', required: true, includeIfNull: false)
  final String key;

  @JsonKey(name: r'value', required: true, includeIfNull: false)
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PutSettingDto && other.key == key && other.value == value;

  @override
  int get hashCode => key.hashCode + value.hashCode;

  factory PutSettingDto.fromJson(Map<String, dynamic> json) =>
      _$PutSettingDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PutSettingDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
