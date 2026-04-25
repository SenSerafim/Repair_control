import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/documents_repository.dart';
import '../domain/document.dart';

/// Параметры запроса списка документов проекта.
/// Нужны для FutureProvider.family — Riverpod кеширует по `==`/`hashCode`,
/// поэтому домен freezed-аналог здесь избыточен.
@immutable
class DocumentsListParams {
  const DocumentsListParams({
    required this.projectId,
    this.stageId,
    this.stepId,
    this.category,
    this.query,
  });

  final String projectId;
  final String? stageId;
  final String? stepId;
  final DocumentCategory? category;
  final String? query;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentsListParams &&
          other.projectId == projectId &&
          other.stageId == stageId &&
          other.stepId == stepId &&
          other.category == category &&
          other.query == query;

  @override
  int get hashCode =>
      Object.hash(projectId, stageId, stepId, category, query);
}

/// Документы проекта с произвольным фильтром.
final documentsListProvider = FutureProvider.autoDispose
    .family<List<Document>, DocumentsListParams>((ref, p) async {
  return ref.read(documentsRepositoryProvider).list(
        projectId: p.projectId,
        stageId: p.stageId,
        stepId: p.stepId,
        category: p.category,
        q: p.query,
      );
});

/// Документы по этапу (для StageDetailScreen).
final documentsByStageProvider = FutureProvider.autoDispose
    .family<List<Document>, ({String projectId, String stageId})>(
        (ref, p) async {
  return ref.read(documentsRepositoryProvider).list(
        projectId: p.projectId,
        stageId: p.stageId,
      );
});

/// Документы по шагу.
final documentsByStepProvider = FutureProvider.autoDispose
    .family<List<Document>, ({String projectId, String stepId})>(
        (ref, p) async {
  return ref.read(documentsRepositoryProvider).list(
        projectId: p.projectId,
        stepId: p.stepId,
      );
});

/// Один документ по id.
final documentByIdProvider =
    FutureProvider.autoDispose.family<Document, String>((ref, id) async {
  return ref.read(documentsRepositoryProvider).get(id);
});

/// Контроллер мутаций над документами (upload/confirm/patch/delete).
/// Чтения — через FutureProvider.family выше.
final documentsControllerProvider = Provider<DocumentsController>((ref) {
  return DocumentsController(ref);
});

class DocumentsController {
  DocumentsController(this._ref);
  final Ref _ref;

  DocumentsRepository get _repo => _ref.read(documentsRepositoryProvider);

  Future<Document> upload({
    required String projectId,
    required DocumentCategory category,
    required String title,
    required String mimeType,
    required Uint8List bytes,
    String? stageId,
    String? stepId,
  }) async {
    final presigned = await _repo.presignUpload(
      projectId: projectId,
      category: category,
      title: title,
      mimeType: mimeType,
      sizeBytes: bytes.length,
      stageId: stageId,
      stepId: stepId,
    );
    await _repo.uploadToStorage(
      presigned: presigned,
      bytes: bytes,
      mimeType: mimeType,
    );
    final doc = await _repo.confirm(
      documentId: presigned.documentId,
      fileKey: presigned.fileKey,
    );
    _invalidateLists(projectId);
    return doc;
  }

  Future<Document> patch({
    required String id,
    required String projectId,
    String? title,
    DocumentCategory? category,
    String? stageId,
    String? stepId,
  }) async {
    final doc = await _repo.patch(
      id: id,
      title: title,
      category: category,
      stageId: stageId,
      stepId: stepId,
    );
    _ref.invalidate(documentByIdProvider(id));
    _invalidateLists(projectId);
    return doc;
  }

  Future<void> delete({required String id, required String projectId}) async {
    await _repo.delete(id);
    _invalidateLists(projectId);
  }

  Future<String> downloadUrl(String id) => _repo.downloadUrl(id);

  void _invalidateLists(String projectId) {
    // FutureProvider.family хранит свои кеши по параметрам; для каждого
    // активного фильтра достаточно invalidate всего семейства.
    _ref
      ..invalidate(documentsListProvider)
      ..invalidate(documentsByStageProvider)
      ..invalidate(documentsByStepProvider);
  }
}
