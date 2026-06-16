//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_tool_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateToolDto {
  /// Returns a new [CreateToolDto] instance.
  CreateToolDto({
    required this.name,

    required this.totalQty,

    this.unit,

    this.photoKey,
  });

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'totalQty', required: true, includeIfNull: false)
  final num totalQty;

  @JsonKey(name: r'unit', required: false, includeIfNull: false)
  final String? unit;

  @JsonKey(name: r'photoKey', required: false, includeIfNull: false)
  final String? photoKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateToolDto &&
          other.name == name &&
          other.totalQty == totalQty &&
          other.unit == unit &&
          other.photoKey == photoKey;

  @override
  int get hashCode =>
      name.hashCode + totalQty.hashCode + unit.hashCode + photoKey.hashCode;

  factory CreateToolDto.fromJson(Map<String, dynamic> json) =>
      _$CreateToolDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateToolDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
