//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'update_article_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateArticleDto {
  /// Returns a new [UpdateArticleDto] instance.
  UpdateArticleDto({this.title, this.body, this.orderIndex});

  @JsonKey(name: r'title', required: false, includeIfNull: false)
  final String? title;

  @JsonKey(name: r'body', required: false, includeIfNull: false)
  final String? body;

  @JsonKey(name: r'orderIndex', required: false, includeIfNull: false)
  final num? orderIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateArticleDto &&
          other.title == title &&
          other.body == body &&
          other.orderIndex == orderIndex;

  @override
  int get hashCode => title.hashCode + body.hashCode + orderIndex.hashCode;

  factory UpdateArticleDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateArticleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateArticleDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
