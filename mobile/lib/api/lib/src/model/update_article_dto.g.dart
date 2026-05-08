// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_article_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateArticleDto _$UpdateArticleDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateArticleDto', json, ($checkedConvert) {
      final val = UpdateArticleDto(
        title: $checkedConvert('title', (v) => v as String?),
        body: $checkedConvert('body', (v) => v as String?),
        orderIndex: $checkedConvert('orderIndex', (v) => v as num?),
      );
      return val;
    });

Map<String, dynamic> _$UpdateArticleDtoToJson(UpdateArticleDto instance) =>
    <String, dynamic>{
      if (instance.title case final value?) 'title': value,
      if (instance.body case final value?) 'body': value,
      if (instance.orderIndex case final value?) 'orderIndex': value,
    };
