import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repair_control/shared/widgets/app_avatar.dart';

import '_helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final palette in AvatarPalette.values) {
    for (final size in [32.0, 48.0, 64.0]) {
      testWidgets(
        'AppAvatar — ${palette.name} @ ${size.toInt()}',
        (tester) async {
          await tester.pumpWidget(
            goldenScaffold(
              size: Size(size + 16, size + 16),
              child: AppAvatar(
                seed: palette.name,
                name: 'Иван Иванов',
                size: size,
                palette: palette,
              ),
            ),
          );
          await expectLater(
            find.byType(AppAvatar),
            matchesGoldenFile('goldens/avatar_${palette.name}_${size.toInt()}.png'),
          );
        },
      );
    }
  }
}
