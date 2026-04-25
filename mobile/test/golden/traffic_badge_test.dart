import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repair_control/shared/widgets/app_traffic_badge.dart';
import 'package:repair_control/shared/widgets/status_pill.dart';

import '_helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  const labels = {
    Semaphore.green: 'В работе',
    Semaphore.yellow: 'На паузе',
    Semaphore.red: 'Просрочка',
    Semaphore.blue: 'На согласовании',
    Semaphore.plan: 'Запланировано',
  };

  for (final s in Semaphore.values) {
    testWidgets('AppTrafficBadge — ${s.name}', (tester) async {
      await tester.pumpWidget(
        goldenScaffold(
          size: const Size(280, 48),
          child: Center(
            child: AppTrafficBadge(label: labels[s]!, semaphore: s),
          ),
        ),
      );
      await expectLater(
        find.byType(AppTrafficBadge),
        matchesGoldenFile('goldens/traffic_badge_${s.name}.png'),
      );
    });
  }
}
