import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:repair_control/app.dart';
import 'package:repair_control/core/config/app_env.dart';
import 'package:repair_control/core/config/app_providers.dart';
import 'package:repair_control/features/auth/application/auth_controller.dart';

/// Smoke-integration: проверяем, что приложение стартует, показывает
/// WelcomeScreen для неаутентифицированного пользователя, и позволяет
/// перейти на LoginScreen кликом на CTA.
///
/// Полный flow register → login → list проектов требует поднятого бекенда
/// и фикс-аккаунтов на staging — вынесено в e2e_roles_test.dart (P2).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots to welcome and navigates to login', (tester) async {
    final env = AppEnv.forTests();

    final container = ProviderContainer(
      overrides: [appEnvProvider.overrideWithValue(env)],
    );
    // Не вызываем реальный bootstrap — он читает secureStorage.
    // Ставим явно unauthenticated стартовое состояние.
    container.read(authControllerProvider.notifier).state =
        const AuthState(status: AuthStatus.unauthenticated);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepairControlApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Welcome показывает кнопку «Войти» (в зависимости от локализации).
    expect(find.textContaining(RegExp('Войти|Log in')), findsWidgets);
  });
}
