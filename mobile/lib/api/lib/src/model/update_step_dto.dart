//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'update_step_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateStepDto {
  /// Returns a new [UpdateStepDto] instance.
  UpdateStepDto({this.title, this.price, this.description, this.assigneeIds});

  @JsonKey(name: r'title', required: false, includeIfNull: false)
  final String? title;

  @JsonKey(name: r'price', required: false, includeIfNull: false)
  final num? price;

  @JsonKey(name: r'description', required: false, includeIfNull: false)
  final String? description;

  @JsonKey(name: r'assigneeIds', required: false, includeIfNull: false)
  final List<String>? assigneeIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateStepDto &&
          other.title == title &&
          other.price == price &&
          other.description == description &&
          other.assigneeIds == assigneeIds;

  @override
  int get hashCode =>
      title.hashCode +
      price.hashCode +
      description.hashCode +
      assigneeIds.hashCode;

  factory UpdateStepDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateStepDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateStepDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
