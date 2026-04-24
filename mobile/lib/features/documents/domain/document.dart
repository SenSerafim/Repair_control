import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document.freezed.dart';

enum DocumentCategory {
  contract,
  act,
  estimate,
  warranty,
  photo,
  blueprint,
  other;

  static DocumentCategory fromString(String? raw) {
    switch (raw) {
      case 'act':
        return DocumentCategory.act;
      case 'estimate':
        return DocumentCategory.estimate;
      case 'warranty':
        return DocumentCategory.warranty;
      case 'photo':
        return DocumentCategory.photo;
      case 'blueprint':
        return DocumentCategory.blueprint;
      case 'other':
        return DocumentCategory.other;
      case 'contract':
      default:
        return DocumentCategory.contract;
    }
  }

  String get apiValue => switch (this) {
        DocumentCategory.contract => 'contract',
        DocumentCategory.act => 'act',
        DocumentCategory.estimate => 'estimate',
        DocumentCategory.warranty => 'warranty',
        DocumentCategory.photo => 'photo',
        DocumentCategory.blueprint => 'blueprint',
        DocumentCategory.other => 'other',
      };

  String get displayName => switch (this) {
        DocumentCategory.contract => 'Договор',
        DocumentCategory.act => 'Акт',
        DocumentCategory.estimate => 'Смета',
        DocumentCategory.warranty => 'Гарантия',
        DocumentCategory.photo => 'Фото',
        DocumentCategory.blueprint => 'Чертёж',
        DocumentCategory.other => 'Прочее',
      };

  IconData get icon => switch (this) {
        DocumentCategory.contract => Icons.description_outlined,
        DocumentCategory.act => Icons.fact_check_outlined,
        DocumentCategory.estimate => Icons.calculate_outlined,
        DocumentCategory.warranty => Icons.verified_user_outlined,
        DocumentCategory.photo => Icons.image_outlined,
        DocumentCategory.blueprint => Icons.architecture_outlined,
        DocumentCategory.other => Icons.folder_open_outlined,
      };
}

@freezed
class Document with _$Document {
  const factory Document({
    required String id,
    required String projectId,
    String? stageId,
    String? stepId,
    required DocumentCategory category,
    required String title,
    required String fileKey,
    String? thumbKey,
    required String mimeType,
    required int sizeBytes,
    required String uploadedBy,
    required bool confirmed,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? url,
    String? thumbUrl,
  }) = _Document;

  static Document parse(Map<String, dynamic> json) => Document(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        stageId: json['stageId'] as String?,
        stepId: json['stepId'] as String?,
        category:
            DocumentCategory.fromString(json['category'] as String?),
        title: json['title'] as String,
        fileKey: json['fileKey'] as String? ?? '',
        thumbKey: json['thumbKey'] as String?,
        mimeType: json['mimeType'] as String,
        sizeBytes: (json['sizeBytes'] as num).toInt(),
        uploadedBy: json['uploadedBy'] as String? ?? '',
        confirmed: json['confirmed'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        url: json['url'] as String?,
        thumbUrl: json['thumbUrl'] as String?,
      );
}

extension DocumentX on Document {
  bool get isPdf => mimeType == 'application/pdf';
  bool get isImage => mimeType.startsWith('image/');
  bool get isOfficeDoc =>
      mimeType ==
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ||
      mimeType ==
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
}
