// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_advance_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateAdvanceDto _$CreateAdvanceDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateAdvanceDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['toUserId', 'amount']);
      final val = CreateAdvanceDto(
        toUserId: $checkedConvert('toUserId', (v) => v as String),
        amount: $checkedConvert('amount', (v) => v as num),
        stageId: $checkedConvert('stageId', (v) => v as String?),
        comment: $checkedConvert('comment', (v) => v as String?),
        photoKey: $checkedConvert('photoKey', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CreateAdvanceDtoToJson(CreateAdvanceDto instance) =>
    <String, dynamic>{
      'toUserId': instance.toUserId,
      'amount': instance.amount,
      if (instance.stageId case final value?) 'stageId': value,
      if (instance.comment case final value?) 'comment': value,
      if (instance.photoKey case final value?) 'photoKey': value,
    };
