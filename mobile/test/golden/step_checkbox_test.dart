import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repair_control/shared/widgets/app_step_checkbox.dart';

import '_helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final checked in [true, false]) {
    testWidgets(
      'AppStepCheckbox — checked=$checked',
      (tester) async {
        await tester.pumpWidget(
          goldenScaffold(
            size: const Size(48, 48),
            child: Center(child: AppStepCheckbox(checked: checked)),
          ),
        );
        await expectLater(
          find.byType(AppStepCheckbox),
          matchesGoldenFile('goldens/step_checkbox_$checked.png'),
        );
      },
    );
  }
}
