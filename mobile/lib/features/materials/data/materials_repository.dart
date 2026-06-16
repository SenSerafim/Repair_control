import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/material_request.dart';

class MaterialsException implements Exception {
  MaterialsException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

class MaterialItemPhotoInput {
  const MaterialItemPhotoInput({
    required this.fileKey,
    required this.mimeType,
    required this.sizeBytes,
    this.thumbKey,
    this.exifCleared = false,
  });

  final String fileKey;
  final String? thumbKey;
  final String mimeType;
  final int sizeBytes;
  final bool exifCleared;

  Map<String, dynamic> toJson() => {
    'fileKey': fileKey,
    if (thumbKey != null) 'thumbKey': thumbKey,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    'exifCleared': exifCleared,
  };
}

class MaterialItemInput {
  const MaterialItemInput({
    required this.name,
    required this.qty,
    this.unit,
    this.note,
    this.pricePerUnit,
    this.dueDate,
    this.photo,
  });

  final String name;
  final double qty;
  final String? unit;
  final String? note;
  final int? pricePerUnit;

  /// Срок поставки позиции (ISO date 'YYYY-MM-DD'). ТЗ NEWFIX §5.5.
  final DateTime? dueDate;

  /// Фото позиции (presigned-загружено). ТЗ NEWFIX §5.2.
  final MaterialItemPhotoInput? photo;

  Map<String, dynamic> toJson() => {
    'name': name,
    'qty': qty,
    if (unit != null) 'unit': unit,
    if (note != null && note!.isNotEmpty) 'note': note,
    if (pricePerUnit != null) 'pricePerUnit': pricePerUnit,
    if (dueDate != null) 'dueDate': dueDate!.toIso8601String().substring(0, 10),
    if (photo != null) 'photo': photo!.toJson(),
  };
}

/// Позиция для частичной приёмки — itemId + actualQty. ТЗ NEWFIX §5.7.
class AcceptedItemInput {
  const AcceptedItemInput({required this.itemId, required this.actualQty});
  final String itemId;
  final double actualQty;

  Map<String, dynamic> toJson() => {'itemId': itemId, 'actualQty': actualQty};
}

class MaterialsRepository {
  MaterialsRepository(this._dio);
  final Dio _dio;

  Future<List<MaterialRequest>> list({
    required String projectId,
    MaterialRequestStatus? status,
  }) => _call(() async {
    final r = await _dio.get<List<dynamic>>(
      '/api/projects/$projectId/materials',
      queryParameters: {if (status != null) 'status': status.apiValue},
    );
    return r.data!
        .map((e) => MaterialRequest.parse(e as Map<String, dynamic>))
        .toList();
  });

  Future<MaterialRequest> get(String id) => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>('/api/materials/$id');
    return MaterialRequest.parse(r.data!);
  });

  /// Создаёт заявку. customer-owner / representative.canApprove → сразу approved.
  /// foreman / master → pending_approval + Approval(material_purchase) заказчику.
  Future<MaterialRequest> create({
    required String projectId,
    required MaterialRecipient recipient,
    required String title,
    required List<MaterialItemInput> items,
    String? stageId,
    String? comment,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/projects/$projectId/materials',
      data: {
        'recipient': recipient.apiValue,
        'title': title,
        if (stageId != null) 'stageId': stageId,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        'items': items.map((e) => e.toJson()).toList(),
      },
    );
    return MaterialRequest.parse(r.data!);
  });

  /// Отметить заявку «Доставлено». ТЗ NEWFIX §5.7 шаг 1.
  /// RBAC: любой member проекта (materials.mark_delivered).
  /// FSM: approved | acceptedPartial → delivered. Идемпотентно из delivered.
  Future<MaterialRequest> markDelivered(String id, {String? comment}) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/materials/$id/mark-delivered',
          data: {if (comment != null && comment.isNotEmpty) 'comment': comment},
        );
        return MaterialRequest.parse(r.data!);
      });

  /// Частичная приёмка с указанием actualQty по позициям. ТЗ NEWFIX §5.7 шаги 4–5.
  /// RBAC: foreman | customer-owner | representative.canApprove.
  /// FSM: delivered → accepted_partial.
  Future<MaterialRequest> acceptPartial(
    String id, {
    required List<AcceptedItemInput> items,
    String? comment,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/materials/$id/accept-partial',
      data: {
        'items': items.map((e) => e.toJson()).toList(),
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
    return MaterialRequest.parse(r.data!);
  });

  /// Полная приёмка — все позиции принимаются по заявленному количеству.
  /// FSM: delivered → accepted_full.
  Future<MaterialRequest> acceptFull(String id, {String? comment}) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/materials/$id/accept-full',
          data: {if (comment != null && comment.isNotEmpty) 'comment': comment},
        );
        return MaterialRequest.parse(r.data!);
      });

  /// Удалить заявку. Backend: автор + статус created|cancelled.
  /// Серафим 08.06.2026: ⋮-меню в шапке заявки.
  Future<void> deleteRequest(String id) => _call(() async {
    await _dio.delete<void>('/api/materials/$id');
  });

  /// ТЗ NEWFIX §5.3: скачать PDF заявки (для share-flow в магазин).
  /// Backend /api/materials/:id/pdf отдаёт PDF inline; auth-header добавляется
  /// через основной Dio (interceptor).
  /// Серафим 08.06.2026: возвращаем bytes + Content-Type, чтобы клиент сам
  /// сохранил с правильным расширением. Backend может вернуть text/html
  /// (fallback puppeteer) — мобилка покажет в браузере, не в PDF reader'е.
  Future<({Uint8List bytes, String mime})> downloadRequestPdf(String id) => _call(() async {
    final r = await _dio.get<List<int>>(
      '/api/materials/$id/pdf',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': 'application/pdf,text/html'},
      ),
    );
    final mime = r.headers.value('content-type') ?? 'application/pdf';
    return (bytes: Uint8List.fromList(r.data!), mime: mime);
  });

  /// Пресайн на загрузку фото позиции (ТЗ NEWFIX §5.2).
  /// Используется общий /api/files/presign-upload, scope='materials/items'.
  /// itemId на этом этапе ещё нет — `MaterialItemPhotoInput.fileKey`
  /// пробрасывается в createRequest и сохраняется как MaterialItemPhoto в БД.
  Future<MaterialItemPresignedUpload> presignItemPhoto({
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
        'scope': 'materials/items',
      },
    );
    return MaterialItemPresignedUpload.fromJson(r.data!);
  });

  /// Raw PUT в S3 (MinIO) через presigned URL. Без auth-interceptor'а —
  /// поэтому собственный Dio, как в steps_repository.
  Future<void> uploadToStorage({
    required MaterialItemPresignedUpload presigned,
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
      throw MaterialsException(AuthFailure.fromApiError(api), api);
    } finally {
      rawDio.close();
    }
  }

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw MaterialsException(AuthFailure.fromApiError(api), api);
    }
  }
}

class MaterialItemPresignedUpload {
  MaterialItemPresignedUpload({
    required this.fileKey,
    required this.url,
    required this.method,
    required this.headers,
    required this.expiresIn,
  });

  factory MaterialItemPresignedUpload.fromJson(Map<String, dynamic> json) =>
      MaterialItemPresignedUpload(
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

final materialsRepositoryProvider = Provider<MaterialsRepository>((ref) {
  return MaterialsRepository(ref.read(dioProvider));
});
