enum KnowledgeCategoryScope { global, projectModule }

KnowledgeCategoryScope _scopeFromString(String raw) =>
    raw == 'project_module'
        ? KnowledgeCategoryScope.projectModule
        : KnowledgeCategoryScope.global;

class KnowledgeCategory {
  const KnowledgeCategory({
    required this.id,
    required this.title,
    required this.scope,
    required this.orderIndex,
    required this.articleCount,
    this.description,
    this.iconKey,
    this.moduleSlug,
  });

  final String id;
  final String title;
  final String? description;
  final String? iconKey;
  final KnowledgeCategoryScope scope;
  final String? moduleSlug;
  final int orderIndex;
  final int articleCount;

  static KnowledgeCategory parse(Map<String, dynamic> json) {
    return KnowledgeCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      iconKey: json['iconKey'] as String?,
      scope: _scopeFromString(json['scope'] as String),
      moduleSlug: json['moduleSlug'] as String?,
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      articleCount: (json['articleCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class KnowledgeArticleSummary {
  const KnowledgeArticleSummary({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.etag,
    required this.version,
  });

  final String id;
  final String title;
  final int orderIndex;
  final String etag;
  final int version;

  static KnowledgeArticleSummary parse(Map<String, dynamic> json) {
    return KnowledgeArticleSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      etag: (json['etag'] as String?) ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

class KnowledgeCategoryDetail {
  const KnowledgeCategoryDetail({
    required this.category,
    required this.articles,
  });

  final KnowledgeCategory category;
  final List<KnowledgeArticleSummary> articles;

  static KnowledgeCategoryDetail parse(Map<String, dynamic> json) {
    final articlesRaw = json['articles'] as List<dynamic>? ?? const [];
    final categoryJson = Map<String, dynamic>.from(json)..remove('articles');
    return KnowledgeCategoryDetail(
      category: KnowledgeCategory.parse(categoryJson),
      articles: articlesRaw
          .map((a) => KnowledgeArticleSummary.parse(a as Map<String, dynamic>))
          .toList(),
    );
  }
}
