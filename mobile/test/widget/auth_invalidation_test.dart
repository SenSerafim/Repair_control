// Тест на cross-session invalidation: проверяет, что хелпер
// `watchAuthAndInvalidate` (lib/core/access/user_scoped_providers.dart)
// действительно инвалидирует переданный список провайдеров при переходе
// authStatus authenticated → unauthenticated.
//
// Это покрывает root cause багов #11 и #12 из QA-документа
// «Контроль ремонта.docx»: новый пользователь видел кешированные данные
// предыдущего, потому что user-scoped провайдеры (tools/chats/team/...)
// созданы без `.autoDispose` и `AuthController.logout()` их не сбрасывал.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/core/access/system_role.dart';
import 'package:repair_control/core/access/user_scoped_providers.dart';
import 'package:repair_control/features/auth/application/auth_controller.dart';

class _TestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState();

  void set({
    required AuthStatus status,
    SystemRole? activeRole,
    String? userId,
  }) {
    state = AuthState(status: status, activeRole: activeRole, userId: userId);
  }
}

void main() {
  test(
      'watchAuthAndInvalidate инвалидирует переданные провайдеры '
      'при logout (authenticated → unauthenticated)', () async {
    var buildCount = 0;
    final probeProvider = FutureProvider<int>((ref) async => ++buildCount);

    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_TestAuthController.new),
      ],
    );
    addTearDown(container.dispose);

    // Регистрируем listener на authControllerProvider в этом container
    // (в продакшне это делает userScopedInvalidationProvider в app.dart).
    final harness = Provider<void>((ref) {
      watchAuthAndInvalidate(ref, [probeProvider]);
    });
    container.read(harness);

    final auth =
        container.read(authControllerProvider.notifier) as _TestAuthController;

    // Initial fetch — build #1
    expect(await container.read(probeProvider.future), 1);

    // Login: unknown → authenticated. Кеш не сбрасывается.
    auth.set(status: AuthStatus.authenticated, userId: 'userA');
    await Future<void>.delayed(Duration.zero);
    expect(await container.read(probeProvider.future), 1,
        reason: 'кеш probeProvider не должен инвалидироваться при логине');

    // Logout: authenticated → unauthenticated. Здесь должен сработать invalidate.
    auth.set(status: AuthStatus.unauthenticated);
    await Future<void>.delayed(Duration.zero);
    expect(await container.read(probeProvider.future), 2,
        reason:
            'после logout probeProvider должен быть инвалидирован — это и был root cause багов #11/#12');
  });

  test(
      'watchAuthAndInvalidate НЕ инвалидирует на initial bootstrap '
      '(unknown → authenticated, без предыдущей сессии)', () async {
    var buildCount = 0;
    final probeProvider = FutureProvider<int>((ref) async => ++buildCount);

    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_TestAuthController.new),
      ],
    );
    addTearDown(container.dispose);

    final harness = Provider<void>((ref) {
      watchAuthAndInvalidate(ref, [probeProvider]);
    });
    container.read(harness);

    final auth =
        container.read(authControllerProvider.notifier) as _TestAuthController;

    expect(await container.read(probeProvider.future), 1);

    // unknown → authenticated (свежий старт приложения с уже сохранёнными
    // токенами). Не должно инвалидировать.
    auth.set(status: AuthStatus.authenticated, userId: 'userA');
    await Future<void>.delayed(Duration.zero);
    expect(await container.read(probeProvider.future), 1);
  });

  test('userScopedProviders содержит ключевые user-data провайдеры', () {
    // Smoke-test, чтобы случайное удаление импорта в user_scoped_providers.dart
    // не сделало список пустым.
    expect(userScopedProviders, isNotEmpty);
    expect(userScopedProviders.length, greaterThan(10),
        reason:
            'утечка между сессиями возможна через любой провайдер с user-data; '
            'если их меньше 10, скорее всего что-то пропущено');
  });
}
