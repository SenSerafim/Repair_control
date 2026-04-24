import 'dart:async';

import 'package:dio/dio.dart';

import '../../storage/secure_storage.dart';

/// Single-flight refresh 401. Если 401 — запрашивает /auth/refresh и
/// повторяет исходный запрос. При провале — триггерит `onSessionExpired`.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required this.storage,
    required this.refreshClient,
    required this.onSessionExpired,
  });

  final SecureStorage storage;

  /// Отдельный Dio без RefreshInterceptor, чтобы не было рекурсии.
  final Dio refreshClient;

  final Future<void> Function() onSessionExpired;

  Completer<String?>? _inflight;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final req = err.requestOptions;

    final alreadyRetried = req.extra['retriedAfterRefresh'] == true;
    final isAuthEndpoint = req.path.contains('/auth/');

    if (status != 401 || alreadyRetried || isAuthEndpoint) {
      return handler.next(err);
    }

    try {
      final newToken = await _refresh();
      if (newToken == null) {
        await onSessionExpired();
        return handler.next(err);
      }

      final opts = Options(
        method: req.method,
        headers: {...req.headers, 'Authorization': 'Bearer $newToken'},
        responseType: req.responseType,
        contentType: req.contentType,
        validateStatus: req.validateStatus,
        extra: {...req.extra, 'retriedAfterRefresh': true},
      );

      final retried = await refreshClient.request<dynamic>(
        req.path,
        data: req.data,
        queryParameters: req.queryParameters,
        options: opts,
        cancelToken: req.cancelToken,
        onReceiveProgress: req.onReceiveProgress,
        onSendProgress: req.onSendProgress,
      );
      return handler.resolve(retried);
    } on DioException catch (e) {
      await onSessionExpired();
      return handler.next(e);
    }
  }

  Future<String?> _refresh() {
    final existing = _inflight;
    if (existing != null) return existing.future;

    final c = Completer<String?>();
    _inflight = c;

    () async {
      try {
        final refresh = await storage.readRefreshToken();
        if (refresh == null || refresh.isEmpty) {
          c.complete(null);
          return;
        }
        final r = await refreshClient.post<Map<String, dynamic>>(
          '/api/auth/refresh',
          data: {'refreshToken': refresh},
          options: Options(extra: {'noAuth': true}),
        );
        final data = r.data;
        final access = data?['accessToken'] as String?;
        final newRefresh = data?['refreshToken'] as String?;
        if (access != null) await storage.writeAccessToken(access);
        if (newRefresh != null) await storage.writeRefreshToken(newRefresh);
        c.complete(access);
      } catch (_) {
        c.complete(null);
      } finally {
        _inflight = null;
      }
    }();

    return c.future;
  }
}
