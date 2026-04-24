import 'package:dio/dio.dart';

import '../../storage/secure_storage.dart';

/// Добавляет Authorization: Bearer <accessToken> в исходящие запросы.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final SecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['noAuth'] == true) {
      handler.next(options);
      return;
    }
    final token = await _storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
