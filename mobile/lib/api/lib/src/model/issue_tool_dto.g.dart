// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_tool_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IssueToolDto _$IssueToolDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('IssueToolDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['toolItemId', 'toUserId', 'qty']);
      final val = IssueToolDto(
        toolItemId: $checkedConvert('toolItemId', (v) => v as String),
        toUserId: $checkedConvert('toUserId', (v) => v as String),
        qty: $checkedConvert('qty', (v) => v as num),
        stageId: $checkedConvert('stageId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$IssueToolDtoToJson(IssueToolDto instance) =>
    <String, dynamic>{
      'toolItemId': instance.toolItemId,
      'toUserId': instance.toUserId,
      'qty': instance.qty,
      if (instance.stageId case final value?) 'stageId': value,
    };
