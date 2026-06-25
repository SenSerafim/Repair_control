import 'dart:typed_data';

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

/// Presign-ответ на загрузку фото инструмента (scope='tools/photos').
class ToolPhotoPresign {
  ToolPhotoPresign({
    required this.fileKey,
    required this.url,
    required this.method,
    required this.headers,
  });

  factory ToolPhotoPresign.fromJson(Map<String, dynamic> json) =>
      ToolPhotoPresign(
        fileKey: (json['key'] ?? json['fileKey']) as String,
        url: (json['url'] ?? json['uploadUrl']) as String,
        method: json['method'] as String? ?? 'PUT',
        headers: (json['headers'] as Map<String, dynamic>? ?? const {}).map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );

  final String fileKey;
  final String url;
  final String method;
  final Map<String, String> headers;
}

/// Self-custody модель (2026-05-12). API:
///   GET    /api/me/tools                         — мои инструменты (профиль)
///   POST   /api/me/tools                         — создать в профиле
///   GET    /api/tools/:id                        — детали
///   PATCH  /api/tools/:id                        — обновить (owner only)
///   DELETE /api/tools/:id                        — удалить (owner only)
///   GET    /api/projects/:pid/tools              — список инструментов проекта
///   POST   /api/projects/:pid/tools              — создать в проекте
///   POST   /api/projects/:pid/tools/attach       — bulk attach «из моих»
///   DELETE /api/projects/:pid/tools/:tid         — открепить от проекта
///   POST   /api/tools/:id/claim                  — self-claim («я забрал»)
///   GET    /api/tools/:id/custody-history        — timeline передач
class ToolsRepository {
  ToolsRepository(this._dio);
  final Dio _dio;

  // ─────────── My Tools (профиль) ───────────

  /// NEWFIX-2 §7.2 — поддержка search/filter на бэке.
  Future<List<ToolItem>> myTools({String? search, ToolStatus? status}) =>
      _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/me/tools',
          queryParameters: {
            if (search != null && search.isNotEmpty) 'search': search,
            if (status != null) 'status': status.apiValue,
          },
        );
        return r.data!
            .map((e) => ToolItem.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<ToolItem> createMyTool({
    required String name,
    String? article,
    String? photoKey,
    String? serial,
    ToolStatus? status,
    String? storageLocation,
    String? assignedEmployeeId,
    DateTime? purchaseDate,
    ToolCondition? condition,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/me/tools',
      data: {
        'name': name,
        if (article != null && article.isNotEmpty) 'article': article,
        if (photoKey != null) 'photoKey': photoKey,
        if (serial != null && serial.isNotEmpty) 'serial': serial,
        if (status != null) 'status': status.apiValue,
        if (storageLocation != null && storageLocation.isNotEmpty)
          'storageLocation': storageLocation,
        if (assignedEmployeeId != null)
          'assignedEmployeeId': assignedEmployeeId,
        if (purchaseDate != null)
          'purchaseDate': purchaseDate.toUtc().toIso8601String(),
        if (condition != null) 'condition': condition.apiValue,
      },
    );
    return ToolItem.parse(r.data!);
  });

  Future<ToolItem> updateTool({
    required String id,
    String? name,
    String? article,
    String? photoKey,
    String? serial,
    ToolStatus? status,
    String? storageLocation,
    String? assignedEmployeeId,
    DateTime? purchaseDate,
    ToolCondition? condition,
  }) => _call(() async {
    final r = await _dio.patch<Map<String, dynamic>>(
      '/api/tools/$id',
      data: {
        if (name != null) 'name': name,
        if (article != null) 'article': article,
        if (photoKey != null) 'photoKey': photoKey,
        if (serial != null) 'serial': serial,
        if (status != null) 'status': status.apiValue,
        if (storageLocation != null) 'storageLocation': storageLocation,
        if (assignedEmployeeId != null)
          'assignedEmployeeId': assignedEmployeeId,
        if (purchaseDate != null)
          'purchaseDate': purchaseDate.toUtc().toIso8601String(),
        if (condition != null) 'condition': condition.apiValue,
      },
    );
    return ToolItem.parse(r.data!);
  });

  /// NEWFIX-2 §9 — выдать инструмент конкретному сотруднику.
  Future<ToolItem> assignToEmployee({
    required String toolId,
    required String employeeUserId,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/tools/$toolId/assign-to-employee',
      data: {'employeeUserId': employeeUserId},
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

  // ─────────── Project Tools ───────────

  Future<List<ToolItem>> listProjectTools(String projectId) => _call(() async {
    final r = await _dio.get<List<dynamic>>('/api/projects/$projectId/tools');
    return r.data!
        .map((e) => ToolItem.parse(e as Map<String, dynamic>))
        .toList();
  });

  /// Создать новый инструмент сразу в проекте. Любая роль member-а.
  /// `ownerId` опционален — по умолчанию текущий пользователь.
  Future<ToolItem> createInProject({
    required String projectId,
    required String name,
    String? ownerId,
    String? article,
    String? photoKey,
    String? serial,
    DateTime? purchaseDate,
    ToolCondition? condition,
    ToolStatus? status,
    String? storageLocation,
    String? assignedEmployeeId,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/projects/$projectId/tools',
      data: {
        'name': name,
        if (ownerId != null) 'ownerId': ownerId,
        if (article != null && article.isNotEmpty) 'article': article,
        if (photoKey != null) 'photoKey': photoKey,
        if (serial != null && serial.isNotEmpty) 'serial': serial,
        if (purchaseDate != null)
          'purchaseDate': purchaseDate.toUtc().toIso8601String(),
        if (condition != null) 'condition': condition.apiValue,
        if (status != null) 'status': status.apiValue,
        if (storageLocation != null && storageLocation.isNotEmpty)
          'storageLocation': storageLocation,
        if (assignedEmployeeId != null)
          'assignedEmployeeId': assignedEmployeeId,
      },
    );
    return ToolItem.parse(r.data!);
  });

  /// Bulk attach — добавить инструменты из «Моих» в проект.
  /// NEWFIX-2 §8.3 — `responsibleUserId` опционален; на бэке default = бригадир.
  Future<List<ToolItem>> attachFromMy({
    required String projectId,
    required List<String> toolItemIds,
    String? responsibleUserId,
  }) => _call(() async {
    final r = await _dio.post<List<dynamic>>(
      '/api/projects/$projectId/tools/attach',
      data: {
        'toolItemIds': toolItemIds,
        if (responsibleUserId != null) 'responsibleUserId': responsibleUserId,
      },
    );
    return r.data!
        .map((e) => ToolItem.parse(e as Map<String, dynamic>))
        .toList();
  });

  /// Открепить инструмент от проекта (только owner).
  Future<void> detachFromProject({
    required String projectId,
    required String toolId,
  }) => _call(() async {
    await _dio.delete<void>('/api/projects/$projectId/tools/$toolId');
  });

  // ─────────── Custody ───────────

  /// Self-claim: текущий пользователь становится holder-ом.
  Future<ToolItem> claim({required String toolId, String? note}) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/tools/$toolId/claim',
          data: {if (note != null && note.isNotEmpty) 'note': note},
        );
        return ToolItem.parse(r.data!);
      });

  Future<List<ToolCustodyEvent>> custodyHistory(String toolId) =>
      _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/tools/$toolId/custody-history',
        );
        return r.data!
            .map((e) => ToolCustodyEvent.parse(e as Map<String, dynamic>))
            .toList();
      });

  /// Presign на фото инструмента. Общий /api/files/presign-upload,
  /// scope='tools/photos' (политика — только изображения, см. FilesModule).
  Future<ToolPhotoPresign> presignPhoto({
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
        'scope': 'tools/photos',
      },
    );
    return ToolPhotoPresign.fromJson(r.data!);
  });

  /// Raw PUT в S3 (MinIO) по presigned URL — отдельный Dio без auth-interceptor.
  Future<void> uploadToStorage({
    required ToolPhotoPresign presigned,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final raw = Dio();
    try {
      await raw.request<void>(
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
      throw ToolsException(AuthFailure.fromApiError(api), api);
    } finally {
      raw.close();
    }
  }

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
