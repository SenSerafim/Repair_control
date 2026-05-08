// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_faq_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateFaqItemDto _$CreateFaqItemDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateFaqItemDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['sectionId', 'question', 'answer', 'orderIndex'],
      );
      final val = CreateFaqItemDto(
        sectionId: $checkedConvert('sectionId', (v) => v as String),
        question: $checkedConvert('question', (v) => v as String),
        answer: $checkedConvert('answer', (v) => v as String),
        orderIndex: $checkedConvert('orderIndex', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$CreateFaqItemDtoToJson(CreateFaqItemDto instance) =>
    <String, dynamic>{
      'sectionId': instance.sectionId,
      'question': instance.question,
      'answer': instance.answer,
      'orderIndex': instance.orderIndex,
    };
