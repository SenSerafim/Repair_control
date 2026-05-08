// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_note_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateNoteDto _$UpdateNoteDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateNoteDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['text']);
      final val = UpdateNoteDto(
        text: $checkedConvert('text', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$UpdateNoteDtoToJson(UpdateNoteDto instance) =>
    <String, dynamic>{'text': instance.text};
