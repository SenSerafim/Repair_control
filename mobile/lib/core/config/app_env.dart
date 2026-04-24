import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppFlavor { dev, staging, prod }

/// Конфиг приложения, загружается из assets/env/.env.<flavor> на старте.
class AppEnv {
  AppEnv._({
    required this.flavor,
    required this.apiBaseUrl,
    required this.wsUrl,
    required this.sentryDsn,
    required this.sentryEnv,
    required this.logLevel,
    required this.vapidKey,
  });

  /// Для интеграционных/widget-тестов. Не читает dotenv.
  @visibleForTesting
  factory AppEnv.forTests({
    AppFlavor flavor = AppFlavor.dev,
    String apiBaseUrl = 'http://localhost:3000',
    String wsUrl = 'ws://localhost:3000',
    String sentryDsn = '',
    String sentryEnv = 'test',
    String logLevel = 'error',
    String vapidKey = '',
  }) =>
      AppEnv._(
        flavor: flavor,
        apiBaseUrl: apiBaseUrl,
        wsUrl: wsUrl,
        sentryDsn: sentryDsn,
        sentryEnv: sentryEnv,
        logLevel: logLevel,
        vapidKey: vapidKey,
      );

  final AppFlavor flavor;
  final String apiBaseUrl;
  final String wsUrl;
  final String sentryDsn;
  final String sentryEnv;
  final String logLevel;

  /// Web Push VAPID key (Firebase Console → Cloud Messaging → Web Push
  /// certificates). Используется только на web. Android/iOS игнорируют.
  final String vapidKey;

  static AppEnv? _instance;
  static AppEnv get I {
    final v = _instance;
    if (v == null) {
      throw StateError('AppEnv.load() must be called before AppEnv.I');
    }
    return v;
  }

  static Future<AppEnv> load(AppFlavor flavor) async {
    final fileName = 'assets/env/.env.${flavor.name}';
    await dotenv.load(fileName: fileName);

    final env = AppEnv._(
      flavor: flavor,
      apiBaseUrl: dotenv.get('API_BASE_URL'),
      wsUrl: dotenv.get('WS_URL'),
      sentryDsn: dotenv.maybeGet('SENTRY_DSN') ?? '',
      sentryEnv: dotenv.maybeGet('SENTRY_ENV') ?? flavor.name,
      logLevel: dotenv.maybeGet('LOG_LEVEL') ?? 'info',
      vapidKey: dotenv.maybeGet('VAPID_KEY') ?? '',
    );
    _instance = env;
    return env;
  }
}
