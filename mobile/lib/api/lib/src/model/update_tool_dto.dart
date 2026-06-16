//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'update_tool_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateToolDto {
  /// Returns a new [UpdateToolDto] instance.
  UpdateToolDto({this.name, this.totalQty, this.unit, this.photoKey});

  @JsonKey(name: r'name', required: false, includeIfNull: false)
  final String? name;

  @JsonKey(name: r'totalQty', required: false, includeIfNull: false)
  final num? totalQty;

  @JsonKey(name: r'unit', required: false, includeIfNull: false)
  final String? unit;

  @JsonKey(name: r'photoKey', required: false, includeIfNull: false)
  final String? photoKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateToolDto &&
          other.name == name &&
          other.totalQty == totalQty &&
          other.unit == unit &&
          other.photoKey == photoKey;

  @override
  int get hashCode =>
      name.hashCode + totalQty.hashCode + unit.hashCode + photoKey.hashCode;

  factory UpdateToolDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateToolDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateToolDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
