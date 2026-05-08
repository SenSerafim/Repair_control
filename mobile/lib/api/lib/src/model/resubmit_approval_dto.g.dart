// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resubmit_approval_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResubmitApprovalDto _$ResubmitApprovalDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ResubmitApprovalDto', json, ($checkedConvert) {
      final val = ResubmitApprovalDto(
        payload: $checkedConvert('payload', (v) => v),
        attachmentKeys: $checkedConvert(
          'attachmentKeys',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ResubmitApprovalDtoToJson(
  ResubmitApprovalDto instance,
) => <String, dynamic>{
  if (instance.payload case final value?) 'payload': value,
  if (instance.attachmentKeys case final value?) 'attachmentKeys': value,
};
