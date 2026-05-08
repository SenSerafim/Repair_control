// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_feedback_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateFeedbackDto _$CreateFeedbackDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateFeedbackDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['text']);
      final val = CreateFeedbackDto(
        text: $checkedConvert('text', (v) => v as String),
        attachmentKeys: $checkedConvert(
          'attachmentKeys',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CreateFeedbackDtoToJson(CreateFeedbackDto instance) =>
    <String, dynamic>{
      'text': instance.text,
      if (instance.attachmentKeys case final value?) 'attachmentKeys': value,
    };
