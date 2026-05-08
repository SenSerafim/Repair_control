// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_faq_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateFaqItemDto _$UpdateFaqItemDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateFaqItemDto', json, ($checkedConvert) {
      final val = UpdateFaqItemDto(
        question: $checkedConvert('question', (v) => v as String?),
        answer: $checkedConvert('answer', (v) => v as String?),
        orderIndex: $checkedConvert('orderIndex', (v) => v as num?),
      );
      return val;
    });

Map<String, dynamic> _$UpdateFaqItemDtoToJson(UpdateFaqItemDto instance) =>
    <String, dynamic>{
      if (instance.question case final value?) 'question': value,
      if (instance.answer case final value?) 'answer': value,
      if (instance.orderIndex case final value?) 'orderIndex': value,
    };
