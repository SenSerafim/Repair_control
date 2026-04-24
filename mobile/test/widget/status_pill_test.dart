import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/shared/widgets/status_pill.dart';

void main() {
  testWidgets('StatusPill показывает label и точку статуса', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusPill(
            label: 'В работе',
            semaphore: Semaphore.yellow,
          ),
        ),
      ),
    );

    expect(find.text('В работе'), findsOneWidget);
  });

  test('Semaphore.* имеют уникальные dot-цвета', () {
    final colors = Semaphore.values.map((s) => s.dot).toSet();
    expect(colors.length, Semaphore.values.length);
  });
}
