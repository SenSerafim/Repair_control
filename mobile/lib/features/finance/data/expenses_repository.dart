import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/expense.dart';

class ExpensesException implements Exception {
  ExpensesException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

class ExpensesRepository {
  ExpensesRepository(this._dio);
  final Dio _dio;

  Future<List<Expense>> list({
    required String projectId,
    String? stageId,
    ExpenseCategory? category,
  }) async {
    try {
      final r = await _dio.get<List<dynamic>>(
        '/api/projects/$projectId/expenses',
        queryParameters: {
          if (stageId != null) 'stageId': stageId,
          if (category != null) 'category': category.apiValue,
        },
      );
      return r.data!
          .map((e) => Expense.parse(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw ExpensesException(AuthFailure.fromApiError(api), api);
    }
  }

  Future<Expense> create({
    required String projectId,
    required ExpenseCategory category,
    required String name,
    required int amountKopecks,
    String? stageId,
    String? comment,
    String? photoKey,
  }) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/api/projects/$projectId/expenses',
        data: {
          'category': category.apiValue,
          'name': name,
          'amount': amountKopecks,
          if (stageId != null) 'stageId': stageId,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          if (photoKey != null) 'photoKey': photoKey,
        },
      );
      return Expense.parse(r.data!);
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw ExpensesException(AuthFailure.fromApiError(api), api);
    }
  }
}

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.read(dioProvider));
});

final projectExpensesProvider =
    FutureProvider.family<List<Expense>, String>((ref, projectId) async {
  return ref.read(expensesRepositoryProvider).list(projectId: projectId);
});
