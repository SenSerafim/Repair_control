import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/shared/widgets/app_button.dart';

void main() {
  testWidgets('AppButton отрисовывает label и реагирует на tap',
      (tester) async {
    var tapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Войти',
            onPressed: () => tapped++,
          ),
        ),
      ),
    );

    expect(find.text('Войти'), findsOneWidget);
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(tapped, 1);
  });

  testWidgets('AppButton в состоянии isLoading показывает индикатор',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Загрузка',
            onPressed: null,
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Загрузка'), findsNothing);
  });
}
