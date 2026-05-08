// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_personal_chat_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePersonalChatDto _$CreatePersonalChatDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreatePersonalChatDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['withUserId']);
  final val = CreatePersonalChatDto(
    withUserId: $checkedConvert('withUserId', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$CreatePersonalChatDtoToJson(
  CreatePersonalChatDto instance,
) => <String, dynamic>{'withUserId': instance.withUserId};
