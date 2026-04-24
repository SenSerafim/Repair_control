import 'package:freezed_annotation/freezed_annotation.dart';

part 'methodology.freezed.dart';

@freezed
class MethodologySection with _$MethodologySection {
  const factory MethodologySection({
    required String id,
    required String title,
    required int orderIndex,
    @Default(<MethodologyArticleSummary>[])
    List<MethodologyArticleSummary> articles,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MethodologySection;

  static MethodologySection parse(Map<String, dynamic> json) {
    final articlesRaw = json['articles'] as List<dynamic>? ?? const [];
    return MethodologySection(
      id: json['id'] as String,
      title: json['title'] as String,
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      articles: articlesRaw
          .map((e) =>
              MethodologyArticleSummary.parse(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

@freezed
class MethodologyArticleSummary with _$MethodologyArticleSummary {
  const factory MethodologyArticleSummary({
    required String id,
    required String sectionId,
    required String title,
    required int orderIndex,
    required int version,
  }) = _MethodologyArticleSummary;

  static MethodologyArticleSummary parse(Map<String, dynamic> json) =>
      MethodologyArticleSummary(
        id: json['id'] as String,
        sectionId: json['sectionId'] as String,
        title: json['title'] as String,
        orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
        version: (json['version'] as num?)?.toInt() ?? 1,
      );
}

@freezed
class MethodologyArticle with _$MethodologyArticle {
  const factory MethodologyArticle({
    required String id,
    required String sectionId,
    required String title,
    required String body,
    required int orderIndex,
    required int version,
    required String etag,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MethodologyArticle;

  static MethodologyArticle parse(Map<String, dynamic> json) =>
      MethodologyArticle(
        id: json['id'] as String,
        sectionId: json['sectionId'] as String,
        title: json['title'] as String,
        body: json['body'] as String? ?? '',
        orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
        version: (json['version'] as num?)?.toInt() ?? 1,
        etag: json['etag'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

@freezed
class MethodologySearchHit with _$MethodologySearchHit {
  const factory MethodologySearchHit({
    required String id,
    required String sectionId,
    required String title,
    required String snippet,
    required double rank,
  }) = _MethodologySearchHit;

  static MethodologySearchHit parse(Map<String, dynamic> json) =>
      MethodologySearchHit(
        id: json['id'] as String,
        sectionId: json['sectionId'] as String,
        title: json['title'] as String,
        snippet: json['snippet'] as String? ?? '',
        rank: (json['rank'] as num?)?.toDouble() ?? 0,
      );
}
