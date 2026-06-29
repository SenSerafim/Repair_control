import 'dart:typed_data';

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
  }) => _call(() async {
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

  /// «Мои согласования» — по всем проектам, где пользователь адресат или
  /// заявитель. Backend: GET /api/me/approvals — возвращает Approval-объекты
  /// с дополнительным полем `projectTitle` для отображения шапки в списке.
  Future<List<MyApprovalItem>> listMine({
    ApprovalScope? scope,
    ApprovalStatus? status,
  }) => _call(() async {
    final r = await _dio.get<List<dynamic>>(
      '/api/me/approvals',
      queryParameters: {
        if (scope != null) 'scope': scope.apiValue,
        if (status != null) 'status': status.apiValue,
      },
    );
    return r.data!
        .map((e) => MyApprovalItem.parse(e as Map<String, dynamic>))
        .toList();
  });

  Future<Approval> get(String id) => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>('/api/approvals/$id');
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
  }) => _call(() async {
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
          data: {if (comment != null && comment.isNotEmpty) 'comment': comment},
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
  }) => _call(() async {
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
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/approvals/$id/cancel',
    );
    return Approval.parse(r.data!);
  });

  /// NEWFIX §4.1 — presign фото-доказательства для scope=defect.
  /// Использует общий /api/files/presign-upload, scope='approvals/defects'
  /// (политика по умолчанию пропускает image/jpeg + image/png).
  Future<ApprovalAttachmentPresign> presignDefectPhoto({
    required String mimeType,
    required int sizeBytes,
    required String originalName,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/files/presign-upload',
      data: {
        'originalName': originalName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'scope': 'approvals/defects',
      },
    );
    return ApprovalAttachmentPresign.fromJson(r.data!);
  });

  /// Raw PUT в S3 (MinIO) — без auth-interceptor'а.
  Future<void> uploadToStorage({
    required ApprovalAttachmentPresign presigned,
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
      final api = ApiError.fromDio(e);
      throw ApprovalsException(AuthFailure.fromApiError(api), api);
    } finally {
      rawDio.close();
    }
  }

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw ApprovalsException(AuthFailure.fromApiError(api), api);
    }
  }
}

class ApprovalAttachmentPresign {
  ApprovalAttachmentPresign({
    required this.fileKey,
    required this.url,
    required this.method,
    required this.headers,
    required this.expiresIn,
  });

  factory ApprovalAttachmentPresign.fromJson(Map<String, dynamic> json) =>
      ApprovalAttachmentPresign(
        fileKey: (json['key'] ?? json['fileKey']) as String,
        url: (json['url'] ?? json['uploadUrl']) as String,
        method: json['method'] as String? ?? 'PUT',
        headers: (json['headers'] as Map<String, dynamic>? ?? const {}).map(
          (k, v) => MapEntry(k, v.toString()),
        ),
        expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 300,
      );

  final String fileKey;
  final String url;
  final String method;
  final Map<String, String> headers;
  final int expiresIn;
}

final approvalsRepositoryProvider = Provider<ApprovalsRepository>((ref) {
  return ApprovalsRepository(ref.read(dioProvider));
});

/// Элемент списка «Мои согласования» — Approval плюс заголовок проекта,
/// инлайн с бэкенда (`/api/me/approvals`).
class MyApprovalItem {
  const MyApprovalItem({required this.approval, required this.projectTitle});

  factory MyApprovalItem.parse(Map<String, dynamic> json) {
    final raw = (json['projectTitle'] as String?)?.trim();
    return MyApprovalItem(
      approval: Approval.parse(json),
      projectTitle: raw == null || raw.isEmpty ? 'Проект' : raw,
    );
  }

  final Approval approval;
  final String projectTitle;
}
