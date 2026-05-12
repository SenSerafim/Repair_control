import 'dart:async';
import 'dart:io';

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

/// Прогресс отправки байт в S3: 0..1, либо null если общий размер неизвестен.
typedef UploadProgress = void Function(double? fraction, int sent, int total);

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
        documentId: (json['documentId'] ?? json['id']) as String,
        fileKey: (json['fileKey'] ?? json['key']) as String,
        url: (json['url'] ?? json['uploadUrl']) as String,
        method: (json['method'] as String?) ?? 'PUT',
        headers: (json['headers'] as Map<String, dynamic>? ?? const {}).map(
          (k, v) => MapEntry(k, v.toString()),
        ),
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

  /// Сколько раз повторить PUT в S3 на сетевых сбоях.
  /// Не ретраим на cancel, 4xx и 5xx с телом — это уже стабильные исходы.
  static const int _uploadRetries = 3;

  Future<List<Document>> list({
    required String projectId,
    String? stageId,
    String? stepId,
    DocumentCategory? category,
    String? q,
  }) => _call(() async {
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
    final r = await _dio.get<Map<String, dynamic>>('/api/documents/$id');
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
    String? description,
    DateTime? documentDate,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/projects/$projectId/documents/presign-upload',
      data: {
        'category': category.apiValue,
        'title': title,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        if (stageId != null) 'stageId': stageId,
        if (stepId != null) 'stepId': stepId,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (documentDate != null)
          'documentDate': documentDate.toUtc().toIso8601String(),
      },
    );
    return PresignedUpload.fromJson(r.data!);
  });

  /// Загрузка файла в S3 стримом — без полного чтения в RAM.
  ///
  /// - `filePath` читается через `File.openRead()` → пригоден для 200 МБ.
  /// - `onProgress` вызывается на каждый чанк, считая дробь 0..1.
  /// - `cancelToken` пробрасывает Cancel из UI (Dio внутри прервёт сокет).
  /// - Retry: до `_uploadRetries` попыток с экспоненциальным backoff на
  ///   network/timeout. На 4xx, 5xx и cancel — отдаём ошибку без ретрая.
  Future<void> uploadToStorage({
    required PresignedUpload presigned,
    required String filePath,
    required int sizeBytes,
    required String mimeType,
    UploadProgress? onProgress,
    CancelToken? cancelToken,
  }) async {
    final file = File(filePath);
    var attempt = 0;
    while (true) {
      attempt++;
      // Каждой попытке нужен свой стрим: File.openRead() одноразовый.
      final raw = Dio();
      final stream = file.openRead().cast<List<int>>();
      try {
        await raw.request<void>(
          presigned.url,
          data: stream,
          cancelToken: cancelToken,
          options: Options(
            method: presigned.method,
            headers: {
              ...presigned.headers,
              Headers.contentLengthHeader: sizeBytes,
              Headers.contentTypeHeader: mimeType,
            },
            sendTimeout: const Duration(minutes: 5),
            receiveTimeout: const Duration(minutes: 1),
          ),
          onSendProgress: onProgress == null
              ? null
              : (sent, total) {
                  final t = total > 0 ? total : sizeBytes;
                  final f = t > 0 ? (sent / t).clamp(0.0, 1.0) : null;
                  onProgress(f, sent, t);
                },
        );
        return;
      } on DioException catch (e) {
        // Cancel — пользователь нажал «Отменить», ретрай тут вреден.
        if (CancelToken.isCancel(e)) {
          throw DocumentsException(
            AuthFailure.unknown,
            ApiError.fromDio(e),
          );
        }
        // На сетевых сбоях ретраим: connection/timeout без response.
        final retryable =
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout;
        if (retryable && attempt < _uploadRetries) {
          // 0.5s → 1.5s → 4.5s
          await Future<void>.delayed(
            Duration(milliseconds: 500 * (1 << (attempt - 1)) + 500),
          );
          continue;
        }
        throw DocumentsException(
          AuthFailure.fromApiError(ApiError.fromDio(e)),
          ApiError.fromDio(e),
        );
      } finally {
        raw.close(force: true);
      }
    }
  }

  Future<Document> confirm({
    required String documentId,
    required String fileKey,
  }) => _call(() async {
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
    String? description,
    DateTime? documentDate,
  }) => _call(() async {
    final r = await _dio.patch<Map<String, dynamic>>(
      '/api/documents/$id',
      data: {
        if (title != null) 'title': title,
        if (category != null) 'category': category.apiValue,
        if (stageId != null) 'stageId': stageId,
        if (stepId != null) 'stepId': stepId,
        if (description != null) 'description': description,
        if (documentDate != null)
          'documentDate': documentDate.toUtc().toIso8601String(),
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
