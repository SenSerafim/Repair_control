import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/shared/widgets/pin_input.dart';

void main() {
  testWidgets('PinInput вызывает onChanged и onCompleted', (tester) async {
    var changed = '';
    String? completed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinInput(
            length: 6,
            onChanged: (v) => changed = v,
            onCompleted: (v) => completed = v,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Вводим 6 цифр
    final field = find.byType(TextField);
    await tester.enterText(field, '123456');
    await tester.pumpAndSettle();

    expect(changed, '123456');
    expect(completed, '123456');
  });

  testWidgets('PinInput показывает errorText', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinInput(
            length: 6,
            onChanged: (_) {},
            errorText: 'Неверный код',
          ),
        ),
      ),
    );

    expect(find.text('Неверный код'), findsOneWidget);
  });
}
