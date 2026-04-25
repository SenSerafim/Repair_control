import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repair_control/shared/widgets/app_house_progress.dart';
import 'package:repair_control/shared/widgets/status_pill.dart';

import '_helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final s in Semaphore.values) {
    testWidgets('AppHouseProgress — ${s.name} 60%', (tester) async {
      await tester.pumpWidget(
        goldenScaffold(
          size: const Size(220, 220),
          child: Center(
            child: AppHouseProgress(percent: 60, semaphore: s),
          ),
        ),
      );
      // Дать одному кадру отрисоваться (CustomPainter) без анимации.
      await tester.pump(const Duration(milliseconds: 100));
      await expectLater(
        find.byType(AppHouseProgress),
        matchesGoldenFile('goldens/house_progress_${s.name}_60.png'),
      );
    });
  }

  testWidgets('AppHouseProgress — green 100% pulse', (tester) async {
    await tester.pumpWidget(
      goldenScaffold(
        size: const Size(220, 220),
        child: const Center(
          child: AppHouseProgress(percent: 100, semaphore: Semaphore.green),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(AppHouseProgress),
      matchesGoldenFile('goldens/house_progress_green_100_pulse.png'),
    );
  });
}
