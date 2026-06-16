//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'return_tool_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReturnToolDto {
  /// Returns a new [ReturnToolDto] instance.
  ReturnToolDto({required this.returnedQty});

  @JsonKey(name: r'returnedQty', required: true, includeIfNull: false)
  final num returnedQty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReturnToolDto && other.returnedQty == returnedQty;

  @override
  int get hashCode => returnedQty.hashCode;

  factory ReturnToolDto.fromJson(Map<String, dynamic> json) =>
      _$ReturnToolDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReturnToolDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
