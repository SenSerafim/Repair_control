// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resolve_payment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResolvePaymentDto _$ResolvePaymentDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ResolvePaymentDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['resolution']);
      final val = ResolvePaymentDto(
        resolution: $checkedConvert('resolution', (v) => v as String),
        adjustAmount: $checkedConvert('adjustAmount', (v) => v as num?),
      );
      return val;
    });

Map<String, dynamic> _$ResolvePaymentDtoToJson(ResolvePaymentDto instance) =>
    <String, dynamic>{
      'resolution': instance.resolution,
      if (instance.adjustAmount case final value?) 'adjustAmount': value,
    };
