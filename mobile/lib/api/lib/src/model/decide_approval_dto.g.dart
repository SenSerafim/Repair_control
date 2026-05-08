// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decide_approval_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DecideApprovalDto _$DecideApprovalDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DecideApprovalDto', json, ($checkedConvert) {
      final val = DecideApprovalDto(
        comment: $checkedConvert('comment', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$DecideApprovalDtoToJson(DecideApprovalDto instance) =>
    <String, dynamic>{if (instance.comment case final value?) 'comment': value};
