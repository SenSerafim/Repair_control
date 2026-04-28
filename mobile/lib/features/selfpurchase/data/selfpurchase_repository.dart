import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/self_purchase.dart';

class SelfPurchaseException implements Exception {
  SelfPurchaseException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

class SelfPurchaseRepository {
  SelfPurchaseRepository(this._dio);
  final Dio _dio;

  Future<List<SelfPurchase>> list({
    required String projectId,
    SelfPurchaseStatus? status,
  }) =>
      _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/projects/$projectId/selfpurchases',
          queryParameters: {
            if (status != null) 'status': status.apiValue,
          },
        );
        return r.data!
            .map((e) => SelfPurchase.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<SelfPurchase> get(String id) => _call(() async {
        final r = await _dio
            .get<Map<String, dynamic>>('/api/selfpurchases/$id');
        return SelfPurchase.parse(r.data!);
      });

  Future<SelfPurchase> create({
    required String projectId,
    required int amount,
    String? stageId,
    String? comment,
    List<String>? photoKeys,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/selfpurchases',
          data: {
            'amount': amount,
            if (stageId != null) 'stageId': stageId,
            if (comment != null && comment.isNotEmpty) 'comment': comment,
            if (photoKeys != null) 'photoKeys': photoKeys,
          },
        );
        return SelfPurchase.parse(r.data!);
      });

  /// approve с поддержкой 3-tier forwarding (master→foreman→customer).
  /// Если [forwardOnApprove] === true и это master-самозакуп, бекенд
  /// автоматически создаёт foreman→customer forward в той же транзакции.
  Future<SelfPurchase> approve({
    required String id,
    String? comment,
    bool forwardOnApprove = false,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/selfpurchases/$id/approve',
          data: {
            if (comment != null && comment.isNotEmpty) 'comment': comment,
            if (forwardOnApprove) 'forwardOnApprove': true,
          },
        );
        return SelfPurchase.parse(r.data!);
      });

  Future<SelfPurchase> reject({required String id, String? comment}) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/selfpurchases/$id/reject',
          data: {
            if (comment != null && comment.isNotEmpty) 'comment': comment,
          },
        );
        return SelfPurchase.parse(r.data!);
      });

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw SelfPurchaseException(AuthFailure.fromApiError(api), api);
    }
  }
}

final selfPurchaseRepositoryProvider =
    Provider<SelfPurchaseRepository>((ref) {
  return SelfPurchaseRepository(ref.read(dioProvider));
});
