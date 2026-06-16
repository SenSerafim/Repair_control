//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'resolve_payment_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ResolvePaymentDto {
  /// Returns a new [ResolvePaymentDto] instance.
  ResolvePaymentDto({required this.resolution, this.adjustAmount});

  @JsonKey(name: r'resolution', required: true, includeIfNull: false)
  final String resolution;

  /// Корректирующая сумма в копейках
  @JsonKey(name: r'adjustAmount', required: false, includeIfNull: false)
  final num? adjustAmount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvePaymentDto &&
          other.resolution == resolution &&
          other.adjustAmount == adjustAmount;

  @override
  int get hashCode => resolution.hashCode + adjustAmount.hashCode;

  factory ResolvePaymentDto.fromJson(Map<String, dynamic> json) =>
      _$ResolvePaymentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ResolvePaymentDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
