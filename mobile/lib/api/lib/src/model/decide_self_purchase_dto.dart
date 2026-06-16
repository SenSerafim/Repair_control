//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'decide_self_purchase_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DecideSelfPurchaseDto {
  /// Returns a new [DecideSelfPurchaseDto] instance.
  DecideSelfPurchaseDto({this.comment});

  @JsonKey(name: r'comment', required: false, includeIfNull: false)
  final String? comment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DecideSelfPurchaseDto && other.comment == comment;

  @override
  int get hashCode => comment.hashCode;

  factory DecideSelfPurchaseDto.fromJson(Map<String, dynamic> json) =>
      _$DecideSelfPurchaseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DecideSelfPurchaseDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
