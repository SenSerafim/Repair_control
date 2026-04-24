import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/pause_reason.dart';
import '../domain/stage.dart';
import '../domain/template.dart';

class StagesException implements Exception {
  StagesException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

class StagesRepository {
  StagesRepository(this._dio);

  final Dio _dio;

  Future<List<Stage>> list(String projectId) => _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/projects/$projectId/stages',
        );
        return r.data!
            .map((e) => Stage.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<Stage> get({required String projectId, required String stageId}) =>
      _call(() async {
        final r = await _dio.get<Map<String, dynamic>>(
          '/api/projects/$projectId/stages/$stageId',
        );
        return Stage.parse(r.data!);
      });

  Future<Stage> create({
    required String projectId,
    required String title,
    int? orderIndex,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    int? workBudget,
    int? materialsBudget,
    List<String>? foremanIds,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/stages',
          data: {
            'title': title,
            if (orderIndex != null) 'orderIndex': orderIndex,
            if (plannedStart != null)
              'plannedStart': plannedStart.toIso8601String(),
            if (plannedEnd != null) 'plannedEnd': plannedEnd.toIso8601String(),
            if (workBudget != null) 'workBudget': workBudget,
            if (materialsBudget != null) 'materialsBudget': materialsBudget,
            if (foremanIds != null) 'foremanIds': foremanIds,
          },
        );
        return Stage.parse(r.data!);
      });

  Future<Stage> update({
    required String projectId,
    required String stageId,
    String? title,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    int? workBudget,
    int? materialsBudget,
    List<String>? foremanIds,
  }) =>
      _call(() async {
        final r = await _dio.patch<Map<String, dynamic>>(
          '/api/projects/$projectId/stages/$stageId',
          data: {
            if (title != null) 'title': title,
            if (plannedStart != null)
              'plannedStart': plannedStart.toIso8601String(),
            if (plannedEnd != null) 'plannedEnd': plannedEnd.toIso8601String(),
            if (workBudget != null) 'workBudget': workBudget,
            if (materialsBudget != null) 'materialsBudget': materialsBudget,
            if (foremanIds != null) 'foremanIds': foremanIds,
          },
        );
        return Stage.parse(r.data!);
      });

  Future<void> reorder({
    required String projectId,
    required List<({String id, int orderIndex})> items,
  }) =>
      _call(() async {
        await _dio.patch<dynamic>(
          '/api/projects/$projectId/stages/reorder',
          data: {
            'items': [
              for (final it in items)
                {'id': it.id, 'orderIndex': it.orderIndex},
            ],
          },
        );
      });

  Future<Stage> start({
    required String projectId,
    required String stageId,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/stages/$stageId/start',
        );
        return Stage.parse(r.data!);
      });

  Future<Stage> pause({
    required String projectId,
    required String stageId,
    required PauseReason reason,
    String? comment,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/stages/$stageId/pause',
          data: {
            'reason': reason.apiValue,
            if (comment != null && comment.isNotEmpty) 'comment': comment,
          },
        );
        return Stage.parse(r.data!);
      });

  Future<Stage> resume({
    required String projectId,
    required String stageId,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/stages/$stageId/resume',
        );
        return Stage.parse(r.data!);
      });

  Future<Stage> sendToReview({
    required String projectId,
    required String stageId,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/stages/$stageId/send-to-review',
        );
        return Stage.parse(r.data!);
      });

  Future<List<StageTemplate>> listPlatformTemplates() => _call(() async {
        final r = await _dio.get<List<dynamic>>('/api/templates/platform');
        return r.data!
            .map((e) => StageTemplate.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<List<StageTemplate>> listUserTemplates() => _call(() async {
        final r = await _dio.get<List<dynamic>>('/api/templates/user');
        return r.data!
            .map((e) => StageTemplate.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<StageTemplate> getTemplate(String id) => _call(() async {
        final r =
            await _dio.get<Map<String, dynamic>>('/api/templates/$id');
        return StageTemplate.parse(r.data!);
      });

  Future<Stage> applyTemplate({
    required String templateId,
    required String projectId,
    DateTime? plannedStart,
    DateTime? plannedEnd,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/templates/$templateId/apply',
          data: {
            'projectId': projectId,
            if (plannedStart != null)
              'plannedStart': plannedStart.toIso8601String(),
            if (plannedEnd != null) 'plannedEnd': plannedEnd.toIso8601String(),
          },
        );
        return Stage.parse(r.data!);
      });

  Future<StageTemplate> saveAsTemplate({
    required String stageId,
    required String title,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/templates/from-stage/$stageId',
          data: {'title': title},
        );
        return StageTemplate.parse(r.data!);
      });

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw StagesException(AuthFailure.fromApiError(api), api);
    }
  }
}

final stagesRepositoryProvider = Provider<StagesRepository>((ref) {
  return StagesRepository(ref.read(dioProvider));
});
