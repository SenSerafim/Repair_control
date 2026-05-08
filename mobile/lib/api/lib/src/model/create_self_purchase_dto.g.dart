// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_self_purchase_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateSelfPurchaseDto _$CreateSelfPurchaseDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateSelfPurchaseDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['amount']);
  final val = CreateSelfPurchaseDto(
    amount: $checkedConvert('amount', (v) => v as num),
    stageId: $checkedConvert('stageId', (v) => v as String?),
    comment: $checkedConvert('comment', (v) => v as String?),
    photoKeys: $checkedConvert(
      'photoKeys',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$CreateSelfPurchaseDtoToJson(
  CreateSelfPurchaseDto instance,
) => <String, dynamic>{
  'amount': instance.amount,
  if (instance.stageId case final value?) 'stageId': value,
  if (instance.comment case final value?) 'comment': value,
  if (instance.photoKeys case final value?) 'photoKeys': value,
};
