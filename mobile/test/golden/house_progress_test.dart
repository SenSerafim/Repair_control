import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repair_control/shared/widgets/app_house_progress.dart';
import 'package:repair_control/shared/widgets/status_pill.dart';

import '_helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> snap(
    WidgetTester tester, {
    required int percent,
    required Semaphore semaphore,
    required String filename,
  }) async {
    await tester.pumpWidget(
      goldenScaffold(
        size: const Size(280, 320),
        child: Center(
          child: AppHouseProgress(
            percent: percent,
            semaphore: semaphore,
            size: 220,
          ),
        ),
      ),
    );
    // 600 ms — хватает чтобы AnimatedOpacity всех слоёв сошёлся.
    await tester.pump(const Duration(milliseconds: 600));
    await expectLater(
      find.byType(AppHouseProgress),
      matchesGoldenFile('goldens/$filename'),
    );

    // Дренируем pending-таймеры flutter_animate (smoke/sparkles).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1500));
  }

  // 5 цветовых вариантов на одном среднем проценте — регрессионный
  // набор для светофора.
  for (final s in Semaphore.values) {
    testWidgets('AppHouseProgress — ${s.name} 60%', (tester) async {
      await snap(
        tester,
        percent: 60,
        semaphore: s,
        filename: 'house_progress_${s.name}_60.png',
      );
    });
  }

  // Прогрессия по этапам — даёт визуальный контроль появления слоёв.
  testWidgets('AppHouseProgress — empty 5%', (tester) async {
    await snap(
      tester,
      percent: 5,
      semaphore: Semaphore.blue,
      filename: 'house_progress_blue_5.png',
    );
  });

  testWidgets('AppHouseProgress — foundation+socle 30%', (tester) async {
    await snap(
      tester,
      percent: 30,
      semaphore: Semaphore.red,
      filename: 'house_progress_red_30.png',
    );
  });

  testWidgets('AppHouseProgress — through ceiling 60%', (tester) async {
    await snap(
      tester,
      percent: 60,
      semaphore: Semaphore.yellow,
      filename: 'house_progress_yellow_60_ceiling.png',
    );
  });

  testWidgets('AppHouseProgress — facade ready 90%', (tester) async {
    await snap(
      tester,
      percent: 90,
      semaphore: Semaphore.green,
      filename: 'house_progress_green_90.png',
    );
  });

  testWidgets('AppHouseProgress — done 100%', (tester) async {
    await snap(
      tester,
      percent: 100,
      semaphore: Semaphore.green,
      filename: 'house_progress_green_100_pulse.png',
    );
  });
}
