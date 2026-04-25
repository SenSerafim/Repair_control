import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repair_control/shared/widgets/app_gradient_progress_bar.dart';

import '_helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final p in ProgressPalette.values) {
    testWidgets('AppGradientProgressBar — ${p.name} 50%', (tester) async {
      await tester.pumpWidget(
        goldenScaffold(
          size: const Size(280, 30),
          child: Center(
            child: SizedBox(
              width: 240,
              child: AppGradientProgressBar(progress: 0.5, palette: p),
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(AppGradientProgressBar),
        matchesGoldenFile('goldens/gradient_progress_bar_${p.name}_50.png'),
      );
    });
  }

  testWidgets('AppGradientProgressBar — overspent 110%', (tester) async {
    await tester.pumpWidget(
      goldenScaffold(
        size: const Size(280, 30),
        child: const Center(
          child: SizedBox(
            width: 240,
            child: AppGradientProgressBar(
              progress: 1.1,
              palette: ProgressPalette.green,
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(AppGradientProgressBar),
      matchesGoldenFile('goldens/gradient_progress_bar_overspent.png'),
    );
  });
}
