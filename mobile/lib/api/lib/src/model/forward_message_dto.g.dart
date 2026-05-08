// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forward_message_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForwardMessageDto _$ForwardMessageDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ForwardMessageDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['toChatId']);
      final val = ForwardMessageDto(
        toChatId: $checkedConvert('toChatId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ForwardMessageDtoToJson(ForwardMessageDto instance) =>
    <String, dynamic>{'toChatId': instance.toChatId};
