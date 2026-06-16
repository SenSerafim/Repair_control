//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_project_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateProjectDto {
  /// Returns a new [CreateProjectDto] instance.
  CreateProjectDto({
    required this.title,

    this.address,

    this.plannedStart,

    this.plannedEnd,

    this.workBudget,

    this.materialsBudget,
  });

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'address', required: false, includeIfNull: false)
  final String? address;

  @JsonKey(name: r'plannedStart', required: false, includeIfNull: false)
  final String? plannedStart;

  @JsonKey(name: r'plannedEnd', required: false, includeIfNull: false)
  final String? plannedEnd;

  @JsonKey(name: r'workBudget', required: false, includeIfNull: false)
  final int? workBudget;

  @JsonKey(name: r'materialsBudget', required: false, includeIfNull: false)
  final int? materialsBudget;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateProjectDto &&
          other.title == title &&
          other.address == address &&
          other.plannedStart == plannedStart &&
          other.plannedEnd == plannedEnd &&
          other.workBudget == workBudget &&
          other.materialsBudget == materialsBudget;

  @override
  int get hashCode =>
      title.hashCode +
      address.hashCode +
      plannedStart.hashCode +
      plannedEnd.hashCode +
      workBudget.hashCode +
      materialsBudget.hashCode;

  factory CreateProjectDto.fromJson(Map<String, dynamic> json) =>
      _$CreateProjectDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateProjectDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
