// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_material_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateMaterialRequestDto _$CreateMaterialRequestDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateMaterialRequestDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['recipient', 'title', 'items']);
  final val = CreateMaterialRequestDto(
    recipient: $checkedConvert(
      'recipient',
      (v) => $enumDecode(_$CreateMaterialRequestDtoRecipientEnumEnumMap, v),
    ),
    title: $checkedConvert('title', (v) => v as String),
    stageId: $checkedConvert('stageId', (v) => v as String?),
    comment: $checkedConvert('comment', (v) => v as String?),
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => MaterialItemInputDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$CreateMaterialRequestDtoToJson(
  CreateMaterialRequestDto instance,
) => <String, dynamic>{
  'recipient':
      _$CreateMaterialRequestDtoRecipientEnumEnumMap[instance.recipient]!,
  'title': instance.title,
  if (instance.stageId case final value?) 'stageId': value,
  if (instance.comment case final value?) 'comment': value,
  'items': instance.items.map((e) => e.toJson()).toList(),
};

const _$CreateMaterialRequestDtoRecipientEnumEnumMap = {
  CreateMaterialRequestDtoRecipientEnum.foreman: 'foreman',
  CreateMaterialRequestDtoRecipientEnum.customer: 'customer',
};
