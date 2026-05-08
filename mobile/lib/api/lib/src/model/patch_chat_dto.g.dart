// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch_chat_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchChatDto _$PatchChatDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PatchChatDto', json, ($checkedConvert) {
      final val = PatchChatDto(
        title: $checkedConvert('title', (v) => v as String?),
        visibleToCustomer: $checkedConvert(
          'visibleToCustomer',
          (v) => v as bool?,
        ),
      );
      return val;
    });

Map<String, dynamic> _$PatchChatDtoToJson(
  PatchChatDto instance,
) => <String, dynamic>{
  if (instance.title case final value?) 'title': value,
  if (instance.visibleToCustomer case final value?) 'visibleToCustomer': value,
};
