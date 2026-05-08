// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'answer_question_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnswerQuestionDto _$AnswerQuestionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AnswerQuestionDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['answer']);
      final val = AnswerQuestionDto(
        answer: $checkedConvert('answer', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AnswerQuestionDtoToJson(AnswerQuestionDto instance) =>
    <String, dynamic>{'answer': instance.answer};
