import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../features/auth/application/auth_controller.dart';
import '../network/dio_factory.dart';
import 'app_env.dart';

/// Провайдеры верхнего уровня. Подключаются в main.dart через ProviderScope.

final appEnvProvider = Provider<AppEnv>((ref) {
  throw UnimplementedError(
    'AppEnv не инициализирован — override в ProviderScope.overrides',
  );
});

final loggerProvider = Provider<Logger>((ref) {
  return Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      lineLength: 100,
      colors: true,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );
});

final dioProvider = Provider<Dio>((ref) {
  final env = ref.read(appEnvProvider);
  final storage = ref.read(secureStorageProvider);
  final logger = ref.read(loggerProvider);
  return DioFactory(
    env: env,
    storage: storage,
    logger: logger,
    onSessionExpired: () async {
      await ref.read(authControllerProvider.notifier).logout();
    },
  ).build();
});

enum ConnectivityStatus { online, offline }

final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) async* {
  final conn = Connectivity();
  yield await _currentStatus(conn);
  await for (final _ in conn.onConnectivityChanged) {
    yield await _currentStatus(conn);
  }
});

Future<ConnectivityStatus> _currentStatus(Connectivity conn) async {
  final results = await conn.checkConnectivity();
  final offline = results.isEmpty ||
      results.every((r) => r == ConnectivityResult.none);
  return offline ? ConnectivityStatus.offline : ConnectivityStatus.online;
}
