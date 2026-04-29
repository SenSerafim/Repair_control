enum KnowledgeAssetKind { image, video, file }

KnowledgeAssetKind _kindFromString(String raw) {
  switch (raw) {
    case 'image':
      return KnowledgeAssetKind.image;
    case 'video':
      return KnowledgeAssetKind.video;
    default:
      return KnowledgeAssetKind.file;
  }
}

class KnowledgeAsset {
  const KnowledgeAsset({
    required this.id,
    required this.articleId,
    required this.kind,
    required this.fileKey,
    required this.mimeType,
    required this.sizeBytes,
    required this.orderIndex,
    this.durationSec,
    this.width,
    this.height,
    this.thumbKey,
    this.caption,
  });

  final String id;
  final String articleId;
  final KnowledgeAssetKind kind;
  final String fileKey;
  final String mimeType;
  final int sizeBytes;
  final int? durationSec;
  final int? width;
  final int? height;
  final String? thumbKey;
  final String? caption;
  final int orderIndex;

  static KnowledgeAsset parse(Map<String, dynamic> json) {
    return KnowledgeAsset(
      id: json['id'] as String,
      articleId: json['articleId'] as String,
      kind: _kindFromString(json['kind'] as String),
      fileKey: json['fileKey'] as String,
      mimeType: json['mimeType'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      durationSec: (json['durationSec'] as num?)?.toInt(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      thumbKey: json['thumbKey'] as String?,
      caption: json['caption'] as String?,
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
    );
  }
}
