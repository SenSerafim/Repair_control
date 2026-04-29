import 'knowledge_asset.dart';

class KnowledgeArticle {
  const KnowledgeArticle({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.body,
    required this.etag,
    required this.version,
    required this.assets,
    this.categoryTitle,
    this.publishedAt,
    this.updatedAt,
  });

  final String id;
  final String categoryId;
  final String? categoryTitle;
  final String title;
  final String body;
  final String etag;
  final int version;
  final List<KnowledgeAsset> assets;
  final DateTime? publishedAt;
  final DateTime? updatedAt;

  static KnowledgeArticle parse(Map<String, dynamic> json) {
    final assetsRaw = json['assets'] as List<dynamic>? ?? const [];
    final cat = json['category'] as Map<String, dynamic>?;
    return KnowledgeArticle(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      categoryTitle: cat?['title'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      etag: (json['etag'] as String?) ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      assets: assetsRaw
          .map((a) => KnowledgeAsset.parse(a as Map<String, dynamic>))
          .toList(),
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );
  }
}
