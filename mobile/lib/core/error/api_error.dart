import 'package:dio/dio.dart';

/// Доменная ошибка API. Маппинг из DioException → структурированный тип,
/// чтобы слой presentation мог показывать правильное сообщение и retry.
class ApiError implements Exception {
  const ApiError({
    required this.kind,
    required this.statusCode,
    this.code,
    this.message,
    this.retryAfterSeconds,
    this.fieldErrors,
  });

  factory ApiError.fromDio(DioException e) {
    final resp = e.response;
    final data = resp?.data;
    String? code;
    String? message;
    Map<String, List<String>>? fieldErrors;
    int? retryAfter;

    if (data is Map<String, dynamic>) {
      code = data['code']?.toString() ?? data['error']?.toString();
      message = data['message']?.toString();
      final ra = data['retryAfter'] ?? data['retry_after'];
      if (ra is num) retryAfter = ra.toInt();
      final fe = data['fieldErrors'];
      if (fe is Map<String, dynamic>) {
        fieldErrors = fe.map(
          (k, v) => MapEntry(k, (v as List).map((e) => e.toString()).toList()),
        );
      }
    }

    final status = resp?.statusCode ?? 0;
    final kind = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        ApiErrorKind.timeout,
      DioExceptionType.connectionError => ApiErrorKind.network,
      DioExceptionType.cancel => ApiErrorKind.cancelled,
      _ => _kindForStatus(status),
    };

    return ApiError(
      kind: kind,
      statusCode: status,
      code: code,
      message: message,
      retryAfterSeconds: retryAfter,
      fieldErrors: fieldErrors,
    );
  }

  static ApiErrorKind _kindForStatus(int s) {
    if (s == 0) return ApiErrorKind.network;
    if (s == 401) return ApiErrorKind.unauthorized;
    if (s == 403) return ApiErrorKind.forbidden;
    if (s == 404) return ApiErrorKind.notFound;
    if (s == 409) return ApiErrorKind.conflict;
    if (s == 422 || s == 400) return ApiErrorKind.validation;
    if (s == 429) return ApiErrorKind.rateLimited;
    if (s >= 500) return ApiErrorKind.server;
    return ApiErrorKind.unknown;
  }

  final ApiErrorKind kind;
  final int statusCode;
  final String? code;
  final String? message;
  final int? retryAfterSeconds;
  final Map<String, List<String>>? fieldErrors;

  @override
  String toString() =>
      'ApiError($kind, $statusCode, code=$code, message=$message)';
}

enum ApiErrorKind {
  network,
  timeout,
  cancelled,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  rateLimited,
  server,
  unknown,
}
