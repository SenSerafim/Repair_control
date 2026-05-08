// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_broadcast_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendBroadcastDto _$SendBroadcastDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SendBroadcastDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['title', 'body', 'filter']);
      final val = SendBroadcastDto(
        title: $checkedConvert('title', (v) => v as String),
        body: $checkedConvert('body', (v) => v as String),
        deepLink: $checkedConvert('deepLink', (v) => v as String?),
        filter: $checkedConvert(
          'filter',
          (v) => BroadcastFilterDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SendBroadcastDtoToJson(SendBroadcastDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'body': instance.body,
      if (instance.deepLink case final value?) 'deepLink': value,
      'filter': instance.filter.toJson(),
    };
