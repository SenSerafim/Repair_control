import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_control/features/notifications/application/notifications_controller.dart';
import 'package:repair_control/shared/widgets/app_notifications_bell.dart';

/// NEWFIX Task 8.1 — тесты переиспользуемого «звоночка с бейджем».
void main() {
  Future<void> pumpBell(
    WidgetTester tester, {
    required int unreadCount,
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            appBar: _BellAppBar(),
            body: SizedBox.shrink(),
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, __) =>
              const Scaffold(body: Text('NOTIFICATIONS_PAGE')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadNotificationsCountProvider.overrideWith((ref) => unreadCount),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
  }

  testWidgets('AppNotificationsBell: count=0 — бейдж не отображается', (
    tester,
  ) async {
    await pumpBell(tester, unreadCount: 0);
    expect(find.byType(AppNotificationsBell), findsOneWidget);
    // Никаких цифр в бейдже быть не должно.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('99+'), findsNothing);
  });

  testWidgets('AppNotificationsBell: count=5 — отображает "5"', (tester) async {
    await pumpBell(tester, unreadCount: 5);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('AppNotificationsBell: count=150 — отображает "99+"', (
    tester,
  ) async {
    await pumpBell(tester, unreadCount: 150);
    expect(find.text('99+'), findsOneWidget);
    expect(find.text('150'), findsNothing);
  });

  testWidgets('AppNotificationsBell: тап → переход на /notifications', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            appBar: _BellAppBar(),
            body: SizedBox.shrink(),
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, __) =>
              const Scaffold(body: Text('NOTIFICATIONS_PAGE')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadNotificationsCountProvider.overrideWith((ref) => 3),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    // На стартовой странице видна цифра "3" в бейдже.
    expect(find.text('3'), findsOneWidget);

    // Тапаем по IconButton внутри AppNotificationsBell.
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    // После перехода: видна страница уведомлений. (go_router `push` кладёт
    // экран поверх в стек, URI `currentConfiguration` при этом может
    // оставаться корневым — проверяем по реально отрисованному widget.)
    expect(find.text('NOTIFICATIONS_PAGE'), findsOneWidget);
  });
}

/// Минимальный AppBar c единственным action — AppNotificationsBell.
/// Размещён в `actions:` чтобы воспроизвести продакшен-сценарий.
class _BellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _BellAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Test'),
      actions: const [AppNotificationsBell()],
    );
  }
}
