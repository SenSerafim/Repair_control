// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mark_read_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MarkReadDto _$MarkReadDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MarkReadDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['messageId']);
      final val = MarkReadDto(
        messageId: $checkedConvert('messageId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$MarkReadDtoToJson(MarkReadDto instance) =>
    <String, dynamic>{'messageId': instance.messageId};
