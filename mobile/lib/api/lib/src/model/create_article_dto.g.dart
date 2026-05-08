// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_article_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateArticleDto _$CreateArticleDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateArticleDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['title', 'body', 'orderIndex']);
      final val = CreateArticleDto(
        title: $checkedConvert('title', (v) => v as String),
        body: $checkedConvert('body', (v) => v as String),
        orderIndex: $checkedConvert('orderIndex', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$CreateArticleDtoToJson(CreateArticleDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'body': instance.body,
      'orderIndex': instance.orderIndex,
    };
