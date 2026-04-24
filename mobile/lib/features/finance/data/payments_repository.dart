import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/budget.dart';
import '../domain/payment.dart';

class PaymentsException implements Exception {
  PaymentsException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

class PaymentsRepository {
  PaymentsRepository(this._dio);
  final Dio _dio;

  Future<ProjectBudget> projectBudget(String projectId) => _call(() async {
        final r = await _dio.get<Map<String, dynamic>>(
          '/api/projects/$projectId/budget',
        );
        return ProjectBudget.parse(r.data!);
      });

  Future<StageBudget?> stageBudget(String stageId) => _call(() async {
        final r = await _dio.get<Map<String, dynamic>?>(
          '/api/stages/$stageId/budget',
        );
        if (r.data == null) return null;
        return StageBudget.parse(r.data!);
      });

  Future<List<Payment>> list({
    required String projectId,
    PaymentStatus? status,
    PaymentKind? kind,
    String? userId,
  }) =>
      _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/projects/$projectId/payments',
          queryParameters: {
            if (status != null) 'status': status.apiValue,
            if (kind != null) 'kind': kind.apiValue,
            if (userId != null) 'userId': userId,
          },
        );
        return r.data!
            .map((e) => Payment.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<Payment> get(String id) => _call(() async {
        final r = await _dio.get<Map<String, dynamic>>('/api/payments/$id');
        return Payment.parse(r.data!);
      });

  Future<Payment> createAdvance({
    required String projectId,
    required String toUserId,
    required int amount,
    String? stageId,
    String? comment,
    String? photoKey,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/payments',
          data: {
            'toUserId': toUserId,
            'amount': amount,
            if (stageId != null) 'stageId': stageId,
            if (comment != null && comment.isNotEmpty) 'comment': comment,
            if (photoKey != null) 'photoKey': photoKey,
          },
        );
        return Payment.parse(r.data!);
      });

  Future<Payment> distribute({
    required String parentPaymentId,
    required String toUserId,
    required int amount,
    String? stageId,
    String? comment,
    String? photoKey,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/payments/$parentPaymentId/distribute',
          data: {
            'toUserId': toUserId,
            'amount': amount,
            if (stageId != null) 'stageId': stageId,
            if (comment != null && comment.isNotEmpty) 'comment': comment,
            if (photoKey != null) 'photoKey': photoKey,
          },
        );
        return Payment.parse(r.data!);
      });

  Future<Payment> confirm(String id) => _call(() async {
        final r = await _dio
            .post<Map<String, dynamic>>('/api/payments/$id/confirm');
        return Payment.parse(r.data!);
      });

  Future<Payment> cancel(String id) => _call(() async {
        final r = await _dio
            .post<Map<String, dynamic>>('/api/payments/$id/cancel');
        return Payment.parse(r.data!);
      });

  Future<Payment> dispute({
    required String id,
    required String reason,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/payments/$id/dispute',
          data: {'reason': reason},
        );
        return Payment.parse(r.data!);
      });

  Future<Payment> resolve({
    required String id,
    required String resolution,
    int? adjustAmount,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/payments/$id/resolve',
          data: {
            'resolution': resolution,
            if (adjustAmount != null) 'adjustAmount': adjustAmount,
          },
        );
        return Payment.parse(r.data!);
      });

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw PaymentsException(AuthFailure.fromApiError(api), api);
    }
  }
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(ref.read(dioProvider));
});
