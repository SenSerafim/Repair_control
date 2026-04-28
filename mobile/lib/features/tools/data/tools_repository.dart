import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/tool.dart';

class ToolsException implements Exception {
  ToolsException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

class ToolsRepository {
  ToolsRepository(this._dio);
  final Dio _dio;

  // ───── Personal tools ─────

  Future<List<ToolItem>> myTools() => _call(() async {
        final r = await _dio.get<List<dynamic>>('/api/me/tools');
        return r.data!
            .map((e) => ToolItem.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<ToolItem> createTool({
    required String name,
    required int totalQty,
    String? unit,
    String? photoKey,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/me/tools',
          data: {
            'name': name,
            'totalQty': totalQty,
            if (unit != null && unit.isNotEmpty) 'unit': unit,
            if (photoKey != null) 'photoKey': photoKey,
          },
        );
        return ToolItem.parse(r.data!);
      });

  Future<ToolItem> updateTool({
    required String id,
    String? name,
    int? totalQty,
    String? unit,
    String? photoKey,
  }) =>
      _call(() async {
        final r = await _dio.patch<Map<String, dynamic>>(
          '/api/tools/$id',
          data: {
            if (name != null) 'name': name,
            if (totalQty != null) 'totalQty': totalQty,
            if (unit != null) 'unit': unit,
            if (photoKey != null) 'photoKey': photoKey,
          },
        );
        return ToolItem.parse(r.data!);
      });

  Future<ToolItem> getTool(String id) => _call(() async {
        final r = await _dio.get<Map<String, dynamic>>('/api/tools/$id');
        return ToolItem.parse(r.data!);
      });

  Future<void> deleteTool(String id) => _call(() async {
        await _dio.delete<void>('/api/tools/$id');
      });

  // ───── Project issuances ─────

  Future<List<ToolIssuance>> listIssuances(String projectId) =>
      _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/projects/$projectId/tool-issuances',
        );
        return r.data!
            .map((e) => ToolIssuance.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<ToolIssuance> issue({
    required String projectId,
    required String toolItemId,
    required String toUserId,
    required int qty,
    String? stageId,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/tool-issuances',
          data: {
            'toolItemId': toolItemId,
            'toUserId': toUserId,
            'qty': qty,
            if (stageId != null) 'stageId': stageId,
          },
        );
        return ToolIssuance.parse(r.data!);
      });

  Future<ToolIssuance> confirm(String id) => _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/tool-issuances/$id/confirm',
        );
        return ToolIssuance.parse(r.data!);
      });

  Future<ToolIssuance> requestReturn({
    required String id,
    required int returnedQty,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/tool-issuances/$id/return',
          data: {'returnedQty': returnedQty},
        );
        return ToolIssuance.parse(r.data!);
      });

  Future<ToolIssuance> returnConfirm(String id) => _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/tool-issuances/$id/return-confirm',
        );
        return ToolIssuance.parse(r.data!);
      });

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw ToolsException(AuthFailure.fromApiError(api), api);
    }
  }
}

final toolsRepositoryProvider = Provider<ToolsRepository>((ref) {
  return ToolsRepository(ref.read(dioProvider));
});
