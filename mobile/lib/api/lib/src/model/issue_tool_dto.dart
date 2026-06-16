//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'issue_tool_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IssueToolDto {
  /// Returns a new [IssueToolDto] instance.
  IssueToolDto({
    required this.toolItemId,

    required this.toUserId,

    required this.qty,

    this.stageId,
  });

  @JsonKey(name: r'toolItemId', required: true, includeIfNull: false)
  final String toolItemId;

  @JsonKey(name: r'toUserId', required: true, includeIfNull: false)
  final String toUserId;

  @JsonKey(name: r'qty', required: true, includeIfNull: false)
  final num qty;

  @JsonKey(name: r'stageId', required: false, includeIfNull: false)
  final String? stageId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IssueToolDto &&
          other.toolItemId == toolItemId &&
          other.toUserId == toUserId &&
          other.qty == qty &&
          other.stageId == stageId;

  @override
  int get hashCode =>
      toolItemId.hashCode + toUserId.hashCode + qty.hashCode + stageId.hashCode;

  factory IssueToolDto.fromJson(Map<String, dynamic> json) =>
      _$IssueToolDtoFromJson(json);

  Map<String, dynamic> toJson() => _$IssueToolDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
