//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'dispute_payment_dto.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DisputePaymentDto {
  /// Returns a new [DisputePaymentDto] instance.
  DisputePaymentDto({

    required  this.reason,
  });

  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DisputePaymentDto &&
      other.reason == reason;

    @override
    int get hashCode =>
        reason.hashCode;

  factory DisputePaymentDto.fromJson(Map<String, dynamic> json) => _$DisputePaymentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DisputePaymentDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

