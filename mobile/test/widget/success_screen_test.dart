import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_control/shared/widgets/success_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget home) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [GoRoute(path: '/', builder: (_, __) => home)],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    // Избегаем pumpAndSettle из-за pulse-анимации AppSuccessBurst.
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('SuccessScreen — заголовок и primary CTA', (tester) async {
    var tapped = false;
    await pump(
      tester,
      SuccessScreen(
        title: 'Готово!',
        subtitle: 'Действие выполнено',
        primaryLabel: 'Продолжить',
        onPrimary: () => tapped = true,
      ),
    );
    expect(find.text('Готово!'), findsOneWidget);
    expect(find.text('Действие выполнено'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.text('Продолжить'));
    expect(tapped, isTrue);
  });

  testWidgets('SuccessScreen isError — красная иконка', (tester) async {
    await pump(
      tester,
      const SuccessScreen(
        title: 'Ошибка',
        isError: true,
      ),
    );
    expect(find.text('Ошибка'), findsOneWidget);
  });
}
