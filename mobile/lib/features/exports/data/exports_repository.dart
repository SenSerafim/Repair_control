import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/export_job.dart';

class ExportsException implements Exception {
  ExportsException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

class ExportsRepository {
  ExportsRepository(this._dio);
  final Dio _dio;

  Future<List<ExportJob>> list(String projectId) => _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/projects/$projectId/exports',
        );
        return r.data!
            .map((e) => ExportJob.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<ExportJob> get(String id) => _call(() async {
        final r = await _dio.get<Map<String, dynamic>>('/api/exports/$id');
        return ExportJob.parse(r.data!);
      });

  Future<ExportJob> create({
    required String projectId,
    required ExportKind kind,
    List<String>? kinds,
    String? stageId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/exports',
          data: {
            'kind': kind.apiValue,
            if (kinds != null && kinds.isNotEmpty) 'kinds': kinds,
            if (stageId != null) 'stageId': stageId,
            if (dateFrom != null) 'dateFrom': dateFrom.toIso8601String(),
            if (dateTo != null) 'dateTo': dateTo.toIso8601String(),
          },
        );
        return ExportJob.parse(r.data!);
      });

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw ExportsException(AuthFailure.fromApiError(api), api);
    }
  }
}

final exportsRepositoryProvider = Provider<ExportsRepository>((ref) {
  return ExportsRepository(ref.read(dioProvider));
});
