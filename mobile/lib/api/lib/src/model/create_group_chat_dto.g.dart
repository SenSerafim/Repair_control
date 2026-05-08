// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_group_chat_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateGroupChatDto _$CreateGroupChatDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateGroupChatDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['title', 'participantUserIds']);
      final val = CreateGroupChatDto(
        title: $checkedConvert('title', (v) => v as String),
        participantUserIds: $checkedConvert(
          'participantUserIds',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CreateGroupChatDtoToJson(CreateGroupChatDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'participantUserIds': instance.participantUserIds,
    };
