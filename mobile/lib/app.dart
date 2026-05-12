import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/access/user_scoped_providers.dart';
import 'core/config/app_locale.dart';
import 'core/config/app_providers.dart';
import 'core/config/app_theme_mode.dart';
import 'core/push/fcm_service.dart';
import 'core/realtime/socket_autoconnect.dart';
import 'core/routing/app_router.dart';
import 'core/storage/offline_handlers.dart';
import 'core/storage/offline_queue.dart';
import 'core/theme/app_theme.dart';
import 'features/chat/application/chats_controller.dart';
import 'features/projects/application/membership_sync.dart';
import 'features/projects/application/projects_list_controller.dart';
import 'shared/widgets/widgets.dart';

/// Root-level ScaffoldMessenger key. Переживает навигацию между экранами,
/// поэтому SnackBar, показанный перед pop()/push(), не падает в
/// _updateScaffolds (lookup ancestor unsafe) и не цепляется за уже
/// отмонтированный Scaffold.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class RepairControlApp extends ConsumerStatefulWidget {
  const RepairControlApp({super.key});

  @override
  ConsumerState<RepairControlApp> createState() => _RepairControlAppState();
}

class _RepairControlAppState extends ConsumerState<RepairControlApp>
    with WidgetsBindingObserver {
  FcmService? _fcm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      ..read(socketAutoconnectProvider)
      // Real-time membership-sync: при добавлении/удалении участника
      // (на любом устройстве) WS-broadcast инвалидирует списки проектов,
      // команды и чатов. Должен быть зарегистрирован ПОСЛЕ socketAutoconnect.
      ..read(membershipSyncProvider)
      // Cross-session invalidation: на logout сбрасываем все user-scoped
      // провайдеры (см. core/access/user_scoped_providers.dart).
      ..read(userScopedInvalidationProvider);
    // Инициализируем FCM (soft-fail — работает без Firebase на dev).
    // Не блокируем критический путь startup: на эмуляторах без Google Play
    // Firebase валится ~8с, всё это время висит fcm.init() и задерживает
    // первую регистрацию роутера/подписок. Присваиваем _fcm сразу — чтобы
    // dispose() мог его освободить, даже если init ещё в полёте.
    final fcm = FcmService(
      logger: ref.read(loggerProvider),
      container: container,
    );
    _fcm = fcm;
    unawaited(
      fcm.init().then((ok) {
        if (ok && mounted) {
          fcm.router = ref.read(routerProvider);
        }
      }),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Backfill при возврате из background: iOS/Android могут «убить» WS-
    // соединение, и события за время offline теряются. socketAutoconnect
    // сам поднимет коннект, а здесь дополнительно инвалидируем главные
    // списки, чтобы пользователь увидел все изменения, произошедшие в фоне
    // (новые проекты в команде, новые чаты, изменения состава).
    if (state == AppLifecycleState.resumed && mounted) {
      ref
        ..invalidate(activeProjectsProvider)
        ..invalidate(myChatsProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fcm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(appLocaleProvider);

    // Реакция на state-конфликты при drain offline-очереди (gaps §2.4):
    // показываем Toast и просим пользователя перезагрузить экран.
    ref.listen(offlineConflictsProvider, (_, next) {
      next.whenData((conflict) {
        final ctx = router.routerDelegate.navigatorKey.currentContext;
        if (ctx == null || !ctx.mounted) return;
        AppToast.show(
          ctx,
          message: conflict.userMessage,
          kind: AppToastKind.info,
        );
      });
    });

    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Repair Control',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) =>
          ConnectivityBanner(child: child ?? const SizedBox.shrink()),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru'), Locale('en')],
      locale: locale,
    );
  }
}
