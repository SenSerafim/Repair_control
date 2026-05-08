// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_message_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EditMessageDto _$EditMessageDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EditMessageDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['text']);
      final val = EditMessageDto(
        text: $checkedConvert('text', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$EditMessageDtoToJson(EditMessageDto instance) =>
    <String, dynamic>{'text': instance.text};
