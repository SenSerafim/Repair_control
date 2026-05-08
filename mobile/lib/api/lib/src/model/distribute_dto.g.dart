// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'distribute_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DistributeDto _$DistributeDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DistributeDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['toUserId', 'amount']);
      final val = DistributeDto(
        toUserId: $checkedConvert('toUserId', (v) => v as String),
        amount: $checkedConvert('amount', (v) => v as num),
        stageId: $checkedConvert('stageId', (v) => v as String?),
        comment: $checkedConvert('comment', (v) => v as String?),
        photoKey: $checkedConvert('photoKey', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$DistributeDtoToJson(DistributeDto instance) =>
    <String, dynamic>{
      'toUserId': instance.toUserId,
      'amount': instance.amount,
      if (instance.stageId case final value?) 'stageId': value,
      if (instance.comment case final value?) 'comment': value,
      if (instance.photoKey case final value?) 'photoKey': value,
    };
