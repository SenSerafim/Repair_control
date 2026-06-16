//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'create_article_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateArticleDto {
  /// Returns a new [CreateArticleDto] instance.
  CreateArticleDto({
    required this.title,

    required this.body,

    required this.orderIndex,
  });

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  /// Markdown
  @JsonKey(name: r'body', required: true, includeIfNull: false)
  final String body;

  @JsonKey(name: r'orderIndex', required: true, includeIfNull: false)
  final num orderIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateArticleDto &&
          other.title == title &&
          other.body == body &&
          other.orderIndex == orderIndex;

  @override
  int get hashCode => title.hashCode + body.hashCode + orderIndex.hashCode;

  factory CreateArticleDto.fromJson(Map<String, dynamic> json) =>
      _$CreateArticleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateArticleDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
