/// Юридическая публикация (PDF), управляемая из админки. Открывается на
/// мобайле через внешний браузер по публичному URL вида
/// `<apiBaseUrl>/legal/public/<slug>`.
class LegalPublication {
  const LegalPublication({
    required this.id,
    required this.kind,
    required this.slug,
    required this.title,
    required this.version,
    required this.sizeBytes,
    this.publishedAt,
  });

  final String id;
  final String kind; // privacy_policy | tos | data_processing_consent | other
  final String slug;
  final String title;
  final int version;
  final int sizeBytes;
  final DateTime? publishedAt;

  static LegalPublication parse(Map<String, dynamic> json) {
    return LegalPublication(
      id: json['id'] as String,
      kind: json['kind'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      version: (json['version'] as num).toInt(),
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
    );
  }

  /// Публичный URL для открытия PDF в браузере.
  /// Slug экспортируется без расширения, но `.pdf` в URL разрешён бекендом.
  String publicUrl(String apiBaseUrl) {
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    return '$base/legal/public/$slug.pdf';
  }
}
