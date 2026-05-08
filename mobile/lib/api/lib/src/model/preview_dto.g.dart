// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preview_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreviewDto _$PreviewDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PreviewDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['filter']);
      final val = PreviewDto(
        filter: $checkedConvert(
          'filter',
          (v) => BroadcastFilterDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PreviewDtoToJson(PreviewDto instance) =>
    <String, dynamic>{'filter': instance.filter.toJson()};
