import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:repair_control/core/config/app_providers.dart';

/// Оборачивает widget в ProviderScope с override'ом AppEnv
/// (в тестах реальный .env не загружается).
Widget wrapForProviders(Widget child) {
  return ProviderScope(
    overrides: [
      appEnvProvider.overrideWith(
        (ref) => throw UnimplementedError('AppEnv stub — override в тестах'),
      ),
    ],
    child: child,
  );
}
