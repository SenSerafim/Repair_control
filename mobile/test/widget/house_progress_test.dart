import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/shared/widgets/app_house_progress.dart';
import 'package:repair_control/shared/widgets/status_pill.dart';

void main() {
  Future<void> pumpAndVerify(
    WidgetTester tester,
    int percent,
    Semaphore semaphore,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppHouseProgress(
              percent: percent,
              semaphore: semaphore,
              subtitle: 'Этап $percent%',
            ),
          ),
        ),
      ),
    );
    // Используем pump(duration), а не pumpAndSettle, т.к. при 100%
    // активна бесконечная pulse-анимация (S17 геймификация).
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Этап $percent%'), findsOneWidget);
  }

  testWidgets('AppHouseProgress не падает на 0/50/100',
      (tester) async {
    await pumpAndVerify(tester, 0, Semaphore.plan);
    await pumpAndVerify(tester, 50, Semaphore.yellow);
    await pumpAndVerify(tester, 100, Semaphore.green);
  });

  testWidgets('AppHouseProgress отражает все 5 цветов', (tester) async {
    for (final s in Semaphore.values) {
      await pumpAndVerify(tester, 42, s);
    }
  });
}
