// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_note_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateNoteDto _$CreateNoteDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateNoteDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['scope', 'text']);
      final val = CreateNoteDto(
        scope: $checkedConvert(
          'scope',
          (v) => $enumDecode(_$CreateNoteDtoScopeEnumEnumMap, v),
        ),
        text: $checkedConvert('text', (v) => v as String),
        addresseeId: $checkedConvert('addresseeId', (v) => v as String?),
        stageId: $checkedConvert('stageId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CreateNoteDtoToJson(CreateNoteDto instance) =>
    <String, dynamic>{
      'scope': _$CreateNoteDtoScopeEnumEnumMap[instance.scope]!,
      'text': instance.text,
      if (instance.addresseeId case final value?) 'addresseeId': value,
      if (instance.stageId case final value?) 'stageId': value,
    };

const _$CreateNoteDtoScopeEnumEnumMap = {
  CreateNoteDtoScopeEnum.personal: 'personal',
  CreateNoteDtoScopeEnum.forMe: 'for_me',
  CreateNoteDtoScopeEnum.stage: 'stage',
};
