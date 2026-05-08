// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_message_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateMessageDto _$CreateMessageDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateMessageDto', json, ($checkedConvert) {
      final val = CreateMessageDto(
        text: $checkedConvert('text', (v) => v as String?),
        attachmentKeys: $checkedConvert(
          'attachmentKeys',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CreateMessageDtoToJson(CreateMessageDto instance) =>
    <String, dynamic>{
      if (instance.text case final value?) 'text': value,
      if (instance.attachmentKeys case final value?) 'attachmentKeys': value,
    };
