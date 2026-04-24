import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/document.dart';

class DocumentsException implements Exception {
  DocumentsException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

class PresignedUpload {
  PresignedUpload({
    required this.documentId,
    required this.fileKey,
    required this.url,
    required this.method,
    required this.headers,
  });

  factory PresignedUpload.fromJson(Map<String, dynamic> json) =>
      PresignedUpload(
        documentId: json['documentId'] as String? ?? json['id'] as String,
        fileKey: json['fileKey'] as String? ?? json['key'] as String,
        url: json['url'] as String,
        method: (json['method'] as String?) ?? 'PUT',
        headers: (json['headers'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, v.toString())),
      );

  final String documentId;
  final String fileKey;
  final String url;
  final String method;
  final Map<String, String> headers;
}

class DocumentsRepository {
  DocumentsRepository(this._dio);
  final Dio _dio;

  Future<List<Document>> list({
    required String projectId,
    String? stageId,
    String? stepId,
    DocumentCategory? category,
    String? q,
  }) =>
      _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/projects/$projectId/documents',
          queryParameters: {
            if (stageId != null) 'stageId': stageId,
            if (stepId != null) 'stepId': stepId,
            if (category != null) 'category': category.apiValue,
            if (q != null && q.isNotEmpty) 'q': q,
          },
        );
        return r.data!
            .map((e) => Document.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<Document> get(String id) => _call(() async {
        final r = await _dio.get<Map<String, dynamic>>(
          '/api/documents/$id',
        );
        return Document.parse(r.data!);
      });

  Future<PresignedUpload> presignUpload({
    required String projectId,
    required DocumentCategory category,
    required String title,
    required String mimeType,
    required int sizeBytes,
    String? stageId,
    String? stepId,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/documents/presign-upload',
          data: {
            'category': category.apiValue,
            'title': title,
            'mimeType': mimeType,
            'sizeBytes': sizeBytes,
            if (stageId != null) 'stageId': stageId,
            if (stepId != null) 'stepId': stepId,
          },
        );
        return PresignedUpload.fromJson(r.data!);
      });

  Future<void> uploadToStorage({
    required PresignedUpload presigned,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final raw = Dio();
    try {
      await raw.request<void>(
        presigned.url,
        data: Stream.fromIterable([bytes]),
        options: Options(
          method: presigned.method,
          headers: {
            ...presigned.headers,
            'Content-Length': bytes.length.toString(),
            'Content-Type': mimeType,
          },
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
    } on DioException catch (e) {
      throw DocumentsException(
        AuthFailure.fromApiError(ApiError.fromDio(e)),
        ApiError.fromDio(e),
      );
    } finally {
      raw.close();
    }
  }

  Future<Document> confirm({
    required String documentId,
    required String fileKey,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/documents/$documentId/confirm',
          data: {'fileKey': fileKey},
        );
        return Document.parse(r.data!);
      });

  Future<Document> patch({
    required String id,
    String? title,
    DocumentCategory? category,
    String? stageId,
    String? stepId,
  }) =>
      _call(() async {
        final r = await _dio.patch<Map<String, dynamic>>(
          '/api/documents/$id',
          data: {
            if (title != null) 'title': title,
            if (category != null) 'category': category.apiValue,
            if (stageId != null) 'stageId': stageId,
            if (stepId != null) 'stepId': stepId,
          },
        );
        return Document.parse(r.data!);
      });

  Future<void> delete(String id) => _call(() async {
        await _dio.delete<void>('/api/documents/$id');
      });

  /// GET /api/documents/:id/download → { url, expiresIn }.
  Future<String> downloadUrl(String id) => _call(() async {
        final r = await _dio.get<Map<String, dynamic>>(
          '/api/documents/$id/download',
        );
        return r.data!['url'] as String;
      });

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw DocumentsException(AuthFailure.fromApiError(api), api);
    }
  }
}

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  return DocumentsRepository(ref.read(dioProvider));
});
