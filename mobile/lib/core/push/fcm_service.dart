import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/notifications/application/notifications_controller.dart';
import '../../firebase_options.dart';
import '../config/app_providers.dart';
import 'deep_link_router.dart';

/// FCM-интеграция. Soft-fail: если Firebase не настроен (нет
/// google-services.json), логируем warning и живём без push.
/// Важно: fake-реализации и тесты НЕ должны инициализировать Firebase.
class FcmService {
  FcmService({
    required this.logger,
    required this.container,
  });

  final Logger logger;
  final ProviderContainer container;

  final _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;
  StreamSubscription<String>? _tokenRefreshSub;

  /// Инициализирует Firebase + permissions + subscriptions.
  /// Возвращает true при успехе, false если FCM недоступен.
  Future<bool> init() async {
    if (_initialized) return true;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      logger.w('FCM disabled: Firebase.initializeApp failed — $e');
      return false;
    }

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      logger.w('FCM permission denied: $e');
    }

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    _onMessageSub = FirebaseMessaging.onMessage.listen(_onForeground);
    _onOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedFromBackground);

    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _recordAndMaybeRoute(initial, autoRoute: true);
      }
    } catch (e) {
      logger.w('getInitialMessage failed: $e');
    }

    // Регистрация device-token. На web обязателен VAPID key —
    // либо через --dart-define=VAPID_KEY=..., либо из
    // assets/env/.env.<flavor> (AppEnv.vapidKey).
    try {
      const vapidFromDefine = String.fromEnvironment('VAPID_KEY');
      final vapidFromEnv = container.read(appEnvProvider).vapidKey;
      final vapidKey = vapidFromDefine.isNotEmpty
          ? vapidFromDefine
          : (vapidFromEnv.isNotEmpty ? vapidFromEnv : null);
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: vapidKey,
      );
      if (token != null) await _registerDevice(token);
    } catch (e) {
      logger.w('FCM getToken failed: $e');
    }

    _tokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen(_registerDevice);

    _initialized = true;
    return true;
  }

  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onOpenedSub?.cancel();
    await _tokenRefreshSub?.cancel();
  }

  Future<void> _registerDevice(String token) async {
    try {
      final repo = container.read(authRepositoryProvider);
      await repo.registerDevice(
        platform: Platform.isIOS ? 'ios' : 'android',
        token: token,
      );
    } on AuthException catch (e) {
      logger.w('Device register failed: ${e.failure}');
    }
  }

  void _onForeground(RemoteMessage message) {
    _recordAndMaybeRoute(message, autoRoute: false);
    // Показываем локальный push для foreground.
    final title = message.notification?.title ?? message.data['title'] as String?;
    final body = message.notification?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return;
    unawaited(
      _local.show(
        message.messageId.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'repair_control_default',
            'Repair Control',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: _payloadString(message.data),
      ),
    );
  }

  void _onOpenedFromBackground(RemoteMessage message) {
    _recordAndMaybeRoute(message, autoRoute: true);
  }

  void _onLocalTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final data = _parsePayload(payload);
    final path = DeepLinkRouter.routeFor(data);
    if (path != null) _navigate(path);
  }

  void _recordAndMaybeRoute(
    RemoteMessage message, {
    required bool autoRoute,
  }) {
    final kind =
        (message.data['kind'] as String?) ?? 'unknown';
    final title =
        message.notification?.title ?? message.data['title'] as String? ?? '';
    final body =
        message.notification?.body ?? message.data['body'] as String? ?? '';
    container.read(notificationsProvider.notifier).push(
          id: message.messageId,
          kind: kind,
          title: title,
          body: body,
          data: Map<String, dynamic>.from(message.data),
        );
    if (autoRoute) {
      final path = DeepLinkRouter.routeFor(
        Map<String, dynamic>.from(message.data),
      );
      if (path != null) _navigate(path);
    }
  }

  void _navigate(String path) {
    // GoRouter-экземпляр достанем из провайдера в bootstrap — здесь
    // не держим прямую ссылку на context, чтобы service-слой оставался
    // платформенно-агностичным.
    final router = _routerRef;
    if (router == null) {
      logger.w('No router registered — cannot navigate to $path');
      return;
    }
    router.push(path);
  }

  GoRouter? _routerRef;
  // ignore: avoid_setters_without_getters
  set router(GoRouter? r) => _routerRef = r;

  String _payloadString(Map<String, dynamic> data) {
    // Простой кодинг «key=value;key2=value2» — без зависимостей на json.
    return data.entries.map((e) => '${e.key}=${e.value}').join(';');
  }

  Map<String, dynamic> _parsePayload(String raw) {
    final out = <String, dynamic>{};
    for (final chunk in raw.split(';')) {
      final eq = chunk.indexOf('=');
      if (eq > 0) {
        out[chunk.substring(0, eq)] = chunk.substring(eq + 1);
      }
    }
    return out;
  }
}
