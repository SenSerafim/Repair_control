// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decide_self_purchase_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DecideSelfPurchaseDto _$DecideSelfPurchaseDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DecideSelfPurchaseDto', json, ($checkedConvert) {
  final val = DecideSelfPurchaseDto(
    comment: $checkedConvert('comment', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$DecideSelfPurchaseDtoToJson(
  DecideSelfPurchaseDto instance,
) => <String, dynamic>{
  if (instance.comment case final value?) 'comment': value,
};
