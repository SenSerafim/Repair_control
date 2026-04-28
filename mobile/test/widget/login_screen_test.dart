import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/auth/presentation/login_screen.dart';

import '../helpers/provider_harness.dart';

void main() {
  testWidgets('LoginScreen рисует форму, ссылку на recovery и кнопку Войти',
      (tester) async {
    await tester.pumpWidget(
      wrapForProviders(const MaterialApp(home: LoginScreen())),
    );

    // Заголовок и приветствие.
    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('С возвращением'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
    expect(find.text('Забыли пароль?'), findsOneWidget);
    // RichText содержит «Нет аккаунта? Зарегистрироваться» — ищем по
    // подстроке через richText finder.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            (w.text.toPlainText()).contains('Зарегистрироваться'),
      ),
      findsOneWidget,
    );

    // Submit пустой формы — экран должен показать состояние ошибки
    // (без crashing). Конкретный текст не проверяем, т.к. сообщение
    // унифицировано в AuthFailure.userMessage.
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    // Кнопка не должна перейти в loading-state, потому что валидация
    // не пропустила форму. Проверяем, что заголовок «Вход» всё ещё на месте.
    expect(find.text('Вход'), findsOneWidget);
  });
}
