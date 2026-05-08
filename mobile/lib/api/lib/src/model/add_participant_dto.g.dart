// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_participant_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddParticipantDto _$AddParticipantDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AddParticipantDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['userId']);
      final val = AddParticipantDto(
        userId: $checkedConvert('userId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AddParticipantDtoToJson(AddParticipantDto instance) =>
    <String, dynamic>{'userId': instance.userId};
