import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/auth/presentation/login_screen.dart';

import '../helpers/provider_harness.dart';

void main() {
  testWidgets('LoginScreen отрисовывает форму и валидирует пустой phone',
      (tester) async {
    await tester.pumpWidget(
      wrapForProviders(const MaterialApp(home: LoginScreen())),
    );

    expect(find.text('Войти'), findsOneWidget);
    expect(find.text('Регистрация'), findsNothing); // нет в login
    expect(find.text('Забыли пароль?'), findsOneWidget);

    // Попытка submit с пустой формой → валидаторы не дают пройти
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.text('Введите телефон'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);
  });
}
