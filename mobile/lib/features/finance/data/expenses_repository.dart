import 'dart:typed_data';

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

  /// NEWFIX TZ-фронт §5.1 — presign на фото чека.
  /// Общий /api/files/presign-upload со scope='expenses/receipts'.
  Future<ExpenseReceiptPresign> presignReceipt({
    required String mimeType,
    required int sizeBytes,
    required String originalName,
  }) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/api/files/presign-upload',
        data: {
          'originalName': originalName,
          'mimeType': mimeType,
          'sizeBytes': sizeBytes,
          'scope': 'expenses/receipts',
        },
      );
      return ExpenseReceiptPresign.fromJson(r.data!);
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw ExpensesException(AuthFailure.fromApiError(api), api);
    }
  }

  /// Raw PUT в S3 (MinIO) через presigned URL — без auth-interceptor.
  Future<void> uploadToStorage({
    required ExpenseReceiptPresign presigned,
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
      throw ExpensesException(AuthFailure.fromApiError(api), api);
    } finally {
      raw.close();
    }
  }
}

class ExpenseReceiptPresign {
  ExpenseReceiptPresign({
    required this.fileKey,
    required this.url,
    required this.method,
    required this.headers,
    required this.expiresIn,
  });

  factory ExpenseReceiptPresign.fromJson(Map<String, dynamic> json) =>
      ExpenseReceiptPresign(
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

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.read(dioProvider));
});

final projectExpensesProvider = FutureProvider.family<List<Expense>, String>((
  ref,
  projectId,
) async {
  return ref.read(expensesRepositoryProvider).list(projectId: projectId);
});
