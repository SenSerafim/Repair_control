import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:repair_control/app.dart';
import 'package:repair_control/core/config/app_env.dart';
import 'package:repair_control/core/config/app_providers.dart';
import 'package:repair_control/features/auth/application/auth_controller.dart';

/// Сценарий ROAD_TO_100 §3.2.1:
///   register → login → create-project → create-stage → start-stage.
///
/// Smoke-уровень: при отсутствии staging-бэка падает на network-step.
/// Полный flow требует `docker compose -f backend/docker-compose.staging.yml up -d`
/// и фикстур-сидов из `backend/prisma/seed.ts`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('registration screen reachable from welcome', (tester) async {
    final env = AppEnv.forTests();
    final container = ProviderContainer(
      overrides: [appEnvProvider.overrideWithValue(env)],
    );
    container.read(authControllerProvider.notifier).state =
        const AuthState(status: AuthStatus.unauthenticated);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepairControlApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // На Welcome есть пути и в login, и в register.
    final hasRegister = find
        .textContaining(RegExp('Регистрация|Sign up'))
        .evaluate()
        .isNotEmpty;
    expect(hasRegister, isTrue);
  });
}
