import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/auth_failure.dart';
import '../../features/chat/application/chats_controller.dart';
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
  ProviderSubscription<AuthState>? _authSub;
  String? _currentToken;

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

    // Получаем FCM-токен (на web обязателен VAPID key — через
    // --dart-define=VAPID_KEY=... или AppEnv.vapidKey). Регистрацию
    // устройства на бэкенде делаем только когда пользователь
    // аутентифицирован (см. подписку ниже): иначе POST /api/me/devices
    // вернёт 401, потому что Authorization-заголовка ещё нет.
    try {
      const vapidFromDefine = String.fromEnvironment('VAPID_KEY');
      final vapidFromEnv = container.read(appEnvProvider).vapidKey;
      final vapidKey = vapidFromDefine.isNotEmpty
          ? vapidFromDefine
          : (vapidFromEnv.isNotEmpty ? vapidFromEnv : null);
      _currentToken = await FirebaseMessaging.instance.getToken(
        vapidKey: vapidKey,
      );
      await _maybeRegisterDevice();
    } catch (e) {
      logger.w('FCM getToken failed: $e');
    }

    _tokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _currentToken = token;
      unawaited(_maybeRegisterDevice());
    });

    // Когда auth переходит в authenticated — регистрируем устройство
    // с уже полученным FCM-токеном (или дожидаемся onTokenRefresh).
    _authSub = container.listen<AuthState>(
      authControllerProvider,
      (prev, next) {
        final wasAuth = prev?.status == AuthStatus.authenticated;
        final isAuth = next.status == AuthStatus.authenticated;
        if (!wasAuth && isAuth) {
          unawaited(_maybeRegisterDevice());
        }
      },
    );

    _initialized = true;
    return true;
  }

  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onOpenedSub?.cancel();
    await _tokenRefreshSub?.cancel();
    _authSub?.close();
  }

  Future<void> _maybeRegisterDevice() async {
    final token = _currentToken;
    if (token == null) return;
    final auth = container.read(authControllerProvider);
    if (auth.status != AuthStatus.authenticated) return;
    await _registerDevice(token);
  }

  Future<void> _registerDevice(String token) async {
    // Бекенд upsert по deviceId — повторные вызовы безопасны.
    // Сетевые сбои и 5xx ретраим с экспоненциальным backoff (2,4,8,16,32с)
    // — иначе FCM-токен не попадёт в БД и push'и не будут доходить до юзера.
    const maxAttempts = 5;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final repo = container.read(authRepositoryProvider);
        await repo.registerDevice(
          platform: Platform.isIOS ? 'ios' : 'android',
          token: token,
        );
        if (attempt > 1) {
          logger.d('Device register succeeded on attempt $attempt');
        }
        return;
      } on AuthException catch (e) {
        final transient = e.failure == AuthFailure.network ||
            e.failure == AuthFailure.server;
        if (transient && attempt < maxAttempts) {
          final delay = Duration(seconds: 1 << attempt);
          logger.w(
            'Device register attempt $attempt failed (${e.failure}), '
            'retry in ${delay.inSeconds}s',
          );
          await Future<void>.delayed(delay);
          continue;
        }
        logger.w('Device register failed (final): ${e.failure}');
        return;
      }
    }
  }

  void _onForeground(RemoteMessage message) {
    _recordAndMaybeRoute(message, autoRoute: false);

    // Push suppression: если пользователь сейчас открыл этот же чат —
    // local-notification избыточен (real-time WS уже доставит сообщение).
    final kind = message.data['kind']?.toString();
    final chatId = message.data['chatId']?.toString();
    if (kind == 'chat_message_new' && chatId != null) {
      final openChatId = container.read(currentChatIdProvider);
      if (openChatId == chatId) {
        logger.d('Push suppressed (in chat $chatId)');
        return;
      }
    }

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
