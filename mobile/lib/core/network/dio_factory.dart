import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config/app_env.dart';
import '../storage/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/idempotency_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/refresh_interceptor.dart';

/// Фабрика Dio-клиента. Настраивает базовый URL, таймауты, интерсепторы.
class DioFactory {
  DioFactory({
    required this.env,
    required this.storage,
    required this.logger,
    required this.onSessionExpired,
  });

  final AppEnv env;
  final SecureStorage storage;
  final Logger logger;
  final Future<void> Function() onSessionExpired;

  Dio build() {
    final base = _buildBase();
    final refreshClient = _buildRefreshClient();

    base.interceptors.addAll([
      AuthInterceptor(storage),
      IdempotencyInterceptor(),
      RefreshInterceptor(
        storage: storage,
        refreshClient: refreshClient,
        onSessionExpired: onSessionExpired,
      ),
      AppLoggingInterceptor(logger),
    ]);

    return base;
  }

  Dio _buildBase() {
    return Dio(
      BaseOptions(
        baseUrl: env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Dio _buildRefreshClient() {
    return Dio(
      BaseOptions(
        baseUrl: env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }
}
