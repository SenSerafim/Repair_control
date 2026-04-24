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
    if (kReleaseMode) {
      Sentry.captureException(error, stackTrace: stack);
    } else {
      debugPrint('Uncaught zone error: $error\n$stack');
    }
  });
}
