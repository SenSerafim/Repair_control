import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_providers.dart';
import 'core/push/fcm_service.dart';
import 'core/realtime/socket_autoconnect.dart';
import 'core/routing/app_router.dart';
import 'core/storage/offline_handlers.dart';
import 'core/storage/offline_queue.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/widgets.dart';

class RepairControlApp extends ConsumerStatefulWidget {
  const RepairControlApp({super.key});

  @override
  ConsumerState<RepairControlApp> createState() => _RepairControlAppState();
}

class _RepairControlAppState extends ConsumerState<RepairControlApp> {
  FcmService? _fcm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initServices());
  }

  Future<void> _initServices() async {
    final container = ProviderScope.containerOf(context, listen: false);
    // Регистрируем offline-handlers (step/substep/note/question).
    registerOfflineHandlers(container);
    // Загружаем offline-очередь с диска.
    await ref.read(offlineQueueProvider).load();
    ref
      // Поднимаем воркер-stream (connectivity → drain).
      ..read(offlineQueueDrainProvider)
      // Автоподключение WebSocket при authenticated.
      ..read(socketAutoconnectProvider);
    // Инициализируем FCM (soft-fail — работает без Firebase на dev).
    final fcm = FcmService(
      logger: ref.read(loggerProvider),
      container: container,
    );
    final ok = await fcm.init();
    if (ok && mounted) {
      fcm.router = ref.read(routerProvider);
      _fcm = fcm;
    }
  }

  @override
  void dispose() {
    _fcm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Repair Control',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) =>
          ConnectivityBanner(child: child ?? const SizedBox.shrink()),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru'), Locale('en')],
      locale: const Locale('ru'),
    );
  }
}
