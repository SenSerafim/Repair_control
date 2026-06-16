//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'distribute_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DistributeDto {
  /// Returns a new [DistributeDto] instance.
  DistributeDto({
    required this.toUserId,

    required this.amount,

    this.stageId,

    this.comment,

    this.photoKey,
  });

  /// Получатель (master)
  @JsonKey(name: r'toUserId', required: true, includeIfNull: false)
  final String toUserId;

  /// Сумма в копейках
  @JsonKey(name: r'amount', required: true, includeIfNull: false)
  final num amount;

  @JsonKey(name: r'stageId', required: false, includeIfNull: false)
  final String? stageId;

  @JsonKey(name: r'comment', required: false, includeIfNull: false)
  final String? comment;

  @JsonKey(name: r'photoKey', required: false, includeIfNull: false)
  final String? photoKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistributeDto &&
          other.toUserId == toUserId &&
          other.amount == amount &&
          other.stageId == stageId &&
          other.comment == comment &&
          other.photoKey == photoKey;

  @override
  int get hashCode =>
      toUserId.hashCode +
      amount.hashCode +
      stageId.hashCode +
      comment.hashCode +
      photoKey.hashCode;

  factory DistributeDto.fromJson(Map<String, dynamic> json) =>
      _$DistributeDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DistributeDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
