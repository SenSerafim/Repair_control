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

/// Один item при создании заявки.
class MaterialItemInput {
  const MaterialItemInput({
    required this.name,
    required this.qty,
    this.unit,
    this.note,
    this.pricePerUnit,
  });

  final String name;
  final double qty;
  final String? unit;
  final String? note;
  final int? pricePerUnit;

  Map<String, dynamic> toJson() => {
        'name': name,
        'qty': qty,
        if (unit != null) 'unit': unit,
        if (note != null && note!.isNotEmpty) 'note': note,
        if (pricePerUnit != null) 'pricePerUnit': pricePerUnit,
      };
}

class MaterialsRepository {
  MaterialsRepository(this._dio);
  final Dio _dio;

  Future<List<MaterialRequest>> list({
    required String projectId,
    MaterialRequestStatus? status,
  }) =>
      _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/projects/$projectId/materials',
          queryParameters: {
            if (status != null) 'status': status.apiValue,
          },
        );
        return r.data!
            .map((e) => MaterialRequest.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<MaterialRequest> get(String id) => _call(() async {
        final r = await _dio.get<Map<String, dynamic>>('/api/materials/$id');
        return MaterialRequest.parse(r.data!);
      });

  Future<MaterialRequest> create({
    required String projectId,
    required MaterialRecipient recipient,
    required String title,
    required List<MaterialItemInput> items,
    String? stageId,
    String? comment,
  }) =>
      _call(() async {
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

  Future<MaterialRequest> send(String id) => _call(() async {
        final r = await _dio
            .post<Map<String, dynamic>>('/api/materials/$id/send');
        return MaterialRequest.parse(r.data!);
      });

  Future<MaterialRequest> markBought({
    required String requestId,
    required String itemId,
    required int pricePerUnit,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/materials/$requestId/items/$itemId/bought',
          data: {'pricePerUnit': pricePerUnit},
        );
        return MaterialRequest.parse(r.data!);
      });

  Future<MaterialRequest> finalizeRequest(String id) => _call(() async {
        final r = await _dio
            .post<Map<String, dynamic>>('/api/materials/$id/finalize');
        return MaterialRequest.parse(r.data!);
      });

  Future<MaterialRequest> confirmDelivery(String id) => _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/materials/$id/confirm-delivery',
        );
        return MaterialRequest.parse(r.data!);
      });

  Future<MaterialRequest> dispute({
    required String id,
    required String reason,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/materials/$id/dispute',
          data: {'reason': reason},
        );
        return MaterialRequest.parse(r.data!);
      });

  Future<MaterialRequest> resolve({
    required String id,
    required String resolution,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/materials/$id/resolve',
          data: {'resolution': resolution},
        );
        return MaterialRequest.parse(r.data!);
      });

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw MaterialsException(AuthFailure.fromApiError(api), api);
    }
  }
}

final materialsRepositoryProvider = Provider<MaterialsRepository>((ref) {
  return MaterialsRepository(ref.read(dioProvider));
});
