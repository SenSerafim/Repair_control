// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispute_payment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisputePaymentDto _$DisputePaymentDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DisputePaymentDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason']);
      final val = DisputePaymentDto(
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DisputePaymentDtoToJson(DisputePaymentDto instance) =>
    <String, dynamic>{'reason': instance.reason};
