import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/config/app_env.dart';
import 'core/config/app_providers.dart';
import 'features/auth/application/auth_controller.dart';

/// Единая точка старта для трёх flavor'ов (dev/staging/prod).
/// Вызывается из main_dev.dart / main_staging.dart / main_prod.dart.
Future<void> bootstrap(AppFlavor flavor) async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Глобальный фильтр известных багов go_router 14.8.1: при rebuild
    // Navigator-стека (после async-операции / WS-обновления провайдера)
    // случается race-condition с `_handlePopPage` / dup `keyReservation`.
    // PR в апстриме (ChrisLoer/go_router#…) ещё не релизнут. До апгрейда
    // на 16.x — глотаем именно эти конкретные сообщения, чтобы UI не
    // умирал, остальные ошибки уходят в Sentry / debugPrint как раньше.
    final defaultOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exception.toString();
      final isGoRouterRace = msg.contains('!keyReservation.contains(key)') ||
          msg.contains('!_debugLocked') ||
          (msg.contains('Null check operator') &&
              (details.stack?.toString() ?? '')
                  .contains('go_router/src/builder.dart'));
      if (isGoRouterRace) {
        debugPrint('[nav-guard] swallowed go_router race: $msg');
        return;
      }
      defaultOnError?.call(details);
    };

    final env = await AppEnv.load(flavor);

    if (env.sentryDsn.isNotEmpty && kReleaseMode) {
      await SentryFlutter.init((o) {
        o
          ..dsn = env.sentryDsn
          ..environment = env.sentryEnv
          ..tracesSampleRate = 0.1
          ..attachStacktrace = true;
      });
    }

    final container = ProviderContainer(
      overrides: [appEnvProvider.overrideWithValue(env)],
    );

    await container.read(authControllerProvider.notifier).bootstrap();

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const RepairControlApp(),
      ),
    );
  }, (error, stack) {
    final msg = error.toString();
    final stackStr = stack.toString();
    // Те же фильтры на уровне zone — `maybePop` бросает async-исключения,
    // которые приходят сюда, а не в FlutterError.onError.
    final isGoRouterRace = msg.contains('!keyReservation.contains(key)') ||
        msg.contains('!_debugLocked') ||
        (msg.contains('Null check operator') &&
            stackStr.contains('go_router/src/builder.dart'));
    if (isGoRouterRace) {
      debugPrint('[nav-guard] swallowed zone error: $msg');
      return;
    }
    if (kReleaseMode) {
      Sentry.captureException(error, stackTrace: stack);
    } else {
      debugPrint('Uncaught zone error: $error\n$stack');
    }
  });
}
