// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ask_question_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AskQuestionDto _$AskQuestionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AskQuestionDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['text', 'addresseeId']);
      final val = AskQuestionDto(
        text: $checkedConvert('text', (v) => v as String),
        addresseeId: $checkedConvert('addresseeId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AskQuestionDtoToJson(AskQuestionDto instance) =>
    <String, dynamic>{
      'text': instance.text,
      'addresseeId': instance.addresseeId,
    };
