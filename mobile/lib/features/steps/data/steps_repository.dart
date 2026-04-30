import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/question.dart';
import '../domain/step.dart';
import '../domain/step_photo.dart';
import '../domain/substep.dart';

class StepsException implements Exception {
  StepsException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

/// Ответ /photos/presign — куда и как загружать.
class PresignedPhoto {
  PresignedPhoto({
    required this.fileKey,
    required this.url,
    required this.method,
    required this.headers,
  });

  factory PresignedPhoto.fromJson(Map<String, dynamic> json) => PresignedPhoto(
        fileKey: (json['fileKey'] ?? json['key']) as String,
        url: (json['url'] ?? json['uploadUrl']) as String,
        method: (json['method'] as String?) ?? 'PUT',
        headers: (json['headers'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, v.toString())),
      );

  final String fileKey;
  final String url;
  final String method;
  final Map<String, String> headers;
}

class StepsRepository {
  StepsRepository(this._dio);

  final Dio _dio;

  Future<List<Step>> listForStage(String stageId) => _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/stages/$stageId/steps',
        );
        return r.data!
            .map((e) => Step.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<Step> getStep(String stepId) => _call(() async {
        final r = await _dio.get<Map<String, dynamic>>('/api/steps/$stepId');
        return Step.parse(r.data!);
      });

  Future<Step> createStep({
    required String stageId,
    required String title,
    StepType type = StepType.regular,
    int? price,
    String? description,
    List<String>? assigneeIds,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/stages/$stageId/steps',
          data: {
            'title': title,
            'type': type == StepType.extra ? 'extra' : 'regular',
            if (price != null) 'price': price,
            if (description != null) 'description': description,
            if (assigneeIds != null) 'assigneeIds': assigneeIds,
          },
        );
        return Step.parse(r.data!);
      });

  Future<Step> updateStep({
    required String stepId,
    String? title,
    int? price,
    String? description,
    List<String>? assigneeIds,
  }) =>
      _call(() async {
        final r = await _dio.patch<Map<String, dynamic>>(
          '/api/steps/$stepId',
          data: {
            if (title != null) 'title': title,
            if (price != null) 'price': price,
            if (description != null) 'description': description,
            if (assigneeIds != null) 'assigneeIds': assigneeIds,
          },
        );
        return Step.parse(r.data!);
      });

  Future<void> deleteStep(String stepId) => _call(() async {
        await _dio.delete<void>('/api/steps/$stepId');
      });

  Future<void> reorderSteps({
    required String stageId,
    required List<({String id, int orderIndex})> items,
  }) =>
      _call(() async {
        await _dio.patch<dynamic>(
          '/api/stages/$stageId/steps/reorder',
          data: {
            'items': [
              for (final it in items)
                {'id': it.id, 'orderIndex': it.orderIndex},
            ],
          },
        );
      });

  Future<Step> completeStep(String stepId) => _call(() async {
        final r = await _dio
            .post<Map<String, dynamic>>('/api/steps/$stepId/complete');
        return Step.parse(r.data!);
      });

  Future<Step> uncompleteStep(String stepId) => _call(() async {
        final r = await _dio
            .post<Map<String, dynamic>>('/api/steps/$stepId/uncomplete');
        return Step.parse(r.data!);
      });

  // ───────── Substeps ─────────

  Future<Substep> addSubstep({
    required String stepId,
    required String text,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/steps/$stepId/substeps',
          data: {'text': text},
        );
        return Substep.parse(r.data!);
      });

  Future<Substep> updateSubstep({
    required String substepId,
    required String text,
  }) =>
      _call(() async {
        final r = await _dio.patch<Map<String, dynamic>>(
          '/api/substeps/$substepId',
          data: {'text': text},
        );
        return Substep.parse(r.data!);
      });

  Future<Substep> completeSubstep(String substepId) => _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/substeps/$substepId/complete',
        );
        return Substep.parse(r.data!);
      });

  Future<Substep> uncompleteSubstep(String substepId) => _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/substeps/$substepId/uncomplete',
        );
        return Substep.parse(r.data!);
      });

  Future<void> deleteSubstep(String substepId) => _call(() async {
        await _dio.delete<void>('/api/substeps/$substepId');
      });

  // ───────── Photos ─────────

  Future<List<StepPhoto>> listPhotos(String stepId) => _call(() async {
        final r = await _dio.get<List<dynamic>>('/api/steps/$stepId/photos');
        return r.data!
            .map((e) => StepPhoto.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<PresignedPhoto> presignPhoto({
    required String stepId,
    required String mime,
    required int sizeBytes,
    String? originalName,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/steps/$stepId/photos/presign',
          data: {
            'mime': mime,
            'size': sizeBytes,
            if (originalName != null) 'originalName': originalName,
          },
        );
        return PresignedPhoto.fromJson(r.data!);
      });

  /// Загружает байты в S3-хранилище (MinIO / Selectel) через presigned URL.
  /// Raw HTTP PUT без auth-interceptor'а — поэтому отдельный Dio.
  Future<void> uploadToStorage({
    required PresignedPhoto presigned,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final rawDio = Dio();
    try {
      await rawDio.request<void>(
        presigned.url,
        data: bytes,
        options: Options(
          method: presigned.method,
          headers: {
            ...presigned.headers,
            'Content-Type': mimeType,
            'Content-Length': bytes.length.toString(),
          },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
    } on DioException catch (e) {
      throw StepsException(
        AuthFailure.fromApiError(ApiError.fromDio(e)),
        ApiError.fromDio(e),
      );
    } finally {
      rawDio.close();
    }
  }

  Future<StepPhoto> confirmPhoto({
    required String stepId,
    required String fileKey,
    required String mimeType,
    required int sizeBytes,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/steps/$stepId/photos/confirm',
          data: {
            'fileKey': fileKey,
            'mimeType': mimeType,
            'sizeBytes': sizeBytes,
          },
        );
        return StepPhoto.parse(r.data!);
      });

  Future<void> deletePhoto(String photoId) => _call(() async {
        await _dio.delete<void>('/api/photos/$photoId');
      });

  // ───────── Questions ─────────

  Future<List<Question>> listQuestions(String stepId) => _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/steps/$stepId/questions',
        );
        return r.data!
            .map((e) => Question.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<Question> askQuestion({
    required String stepId,
    required String text,
    required String addresseeId,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/steps/$stepId/questions',
          data: {'text': text, 'addresseeId': addresseeId},
        );
        return Question.parse(r.data!);
      });

  Future<Question> answerQuestion({
    required String questionId,
    required String answer,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/questions/$questionId/answer',
          data: {'answer': answer},
        );
        return Question.parse(r.data!);
      });

  Future<Question> closeQuestion(String questionId) => _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/questions/$questionId/close',
        );
        return Question.parse(r.data!);
      });

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw StepsException(AuthFailure.fromApiError(api), api);
    }
  }
}

final stepsRepositoryProvider = Provider<StepsRepository>((ref) {
  return StepsRepository(ref.read(dioProvider));
});
