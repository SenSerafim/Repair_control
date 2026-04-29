class KnowledgeSearchHit {
  const KnowledgeSearchHit({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.snippet,
    required this.rank,
  });

  final String id;
  final String categoryId;
  final String title;
  final String snippet;
  final double rank;

  static KnowledgeSearchHit parse(Map<String, dynamic> json) {
    return KnowledgeSearchHit(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      title: json['title'] as String,
      snippet: (json['snippet'] as String?) ?? '',
      rank: (json['rank'] as num?)?.toDouble() ?? 0,
    );
  }
}
