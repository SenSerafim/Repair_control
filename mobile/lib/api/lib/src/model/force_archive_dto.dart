//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'force_archive_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ForceArchiveDto {
  /// Returns a new [ForceArchiveDto] instance.
  ForceArchiveDto({required this.reason});

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForceArchiveDto && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  factory ForceArchiveDto.fromJson(Map<String, dynamic> json) =>
      _$ForceArchiveDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ForceArchiveDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
