import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repair_control/shared/widgets/app_gradient_hero.dart';

import '_helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final p in HeroPalette.values) {
    testWidgets('AppGradientHero — ${p.name}', (tester) async {
      await tester.pumpWidget(
        goldenScaffold(
          size: const Size(360, 200),
          child: AppGradientHero(
            palette: p,
            child: const Text(
              'Контроль ремонта',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(AppGradientHero),
        matchesGoldenFile('goldens/gradient_hero_${p.name}.png'),
      );
    });
  }
}
