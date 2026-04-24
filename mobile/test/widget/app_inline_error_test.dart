import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/shared/widgets/app_states.dart';

void main() {
  testWidgets('AppInlineError показывает иконку и сообщение', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppInlineError(message: 'Что-то пошло не так'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Что-то пошло не так'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}
