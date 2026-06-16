//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:repair_control_api/src/model/broadcast_filter_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'preview_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PreviewDto {
  /// Returns a new [PreviewDto] instance.
  PreviewDto({required this.filter});

  @JsonKey(name: r'filter', required: true, includeIfNull: false)
  final BroadcastFilterDto filter;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PreviewDto && other.filter == filter;

  @override
  int get hashCode => filter.hashCode;

  factory PreviewDto.fromJson(Map<String, dynamic> json) =>
      _$PreviewDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PreviewDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
