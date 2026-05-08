// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mark_bought_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MarkBoughtDto _$MarkBoughtDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MarkBoughtDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['pricePerUnit']);
      final val = MarkBoughtDto(
        pricePerUnit: $checkedConvert('pricePerUnit', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$MarkBoughtDtoToJson(MarkBoughtDto instance) =>
    <String, dynamic>{'pricePerUnit': instance.pricePerUnit};
