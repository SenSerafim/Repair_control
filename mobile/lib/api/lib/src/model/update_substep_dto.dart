//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'update_substep_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateSubstepDto {
  /// Returns a new [UpdateSubstepDto] instance.
  UpdateSubstepDto({this.text});

  @JsonKey(name: r'text', required: false, includeIfNull: false)
  final String? text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UpdateSubstepDto && other.text == text;

  @override
  int get hashCode => text.hashCode;

  factory UpdateSubstepDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateSubstepDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateSubstepDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
