import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/approval.dart';

class ApprovalsException implements Exception {
  ApprovalsException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

class ApprovalsRepository {
  ApprovalsRepository(this._dio);

  final Dio _dio;

  Future<List<Approval>> list({
    required String projectId,
    ApprovalScope? scope,
    ApprovalStatus? status,
    String? addresseeId,
  }) =>
      _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/projects/$projectId/approvals',
          queryParameters: {
            if (scope != null) 'scope': scope.apiValue,
            if (status != null) 'status': status.apiValue,
            if (addresseeId != null) 'addresseeId': addresseeId,
          },
        );
        return r.data!
            .map((e) => Approval.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<Approval> get(String id) => _call(() async {
        final r =
            await _dio.get<Map<String, dynamic>>('/api/approvals/$id');
        return Approval.parse(r.data!);
      });

  Future<Approval> create({
    required String projectId,
    required ApprovalScope scope,
    required String addresseeId,
    String? stageId,
    String? stepId,
    Map<String, dynamic>? payload,
    List<String>? attachmentKeys,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/approvals',
          data: {
            'scope': scope.apiValue,
            'addresseeId': addresseeId,
            if (stageId != null) 'stageId': stageId,
            if (stepId != null) 'stepId': stepId,
            if (payload != null) 'payload': payload,
            if (attachmentKeys != null) 'attachmentKeys': attachmentKeys,
          },
        );
        return Approval.parse(r.data!);
      });

  Future<Approval> approve({required String id, String? comment}) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/approvals/$id/approve',
          data: {
            if (comment != null && comment.isNotEmpty) 'comment': comment,
          },
        );
        return Approval.parse(r.data!);
      });

  Future<Approval> reject({required String id, required String comment}) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/approvals/$id/reject',
          data: {'comment': comment},
        );
        return Approval.parse(r.data!);
      });

  Future<Approval> resubmit({
    required String id,
    Map<String, dynamic>? payload,
    List<String>? attachmentKeys,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/approvals/$id/resubmit',
          data: {
            if (payload != null) 'payload': payload,
            if (attachmentKeys != null) 'attachmentKeys': attachmentKeys,
          },
        );
        return Approval.parse(r.data!);
      });

  Future<Approval> cancel(String id) => _call(() async {
        final r = await _dio
            .post<Map<String, dynamic>>('/api/approvals/$id/cancel');
        return Approval.parse(r.data!);
      });

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw ApprovalsException(AuthFailure.fromApiError(api), api);
    }
  }
}

final approvalsRepositoryProvider = Provider<ApprovalsRepository>((ref) {
  return ApprovalsRepository(ref.read(dioProvider));
});
