import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repair_control/shared/widgets/app_message_bubble.dart';

import '_helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final isMine in [true, false]) {
    final me = isMine ? 'mine' : 'incoming';

    testWidgets('AppMessageBubble — $me default', (tester) async {
      await tester.pumpWidget(
        goldenScaffold(
          size: const Size(280, 120),
          child: Align(
            alignment:
                isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: AppMessageBubble(
              text: 'Сообщение чата для пиксель-перфект теста',
              isMine: isMine,
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(AppMessageBubble),
        matchesGoldenFile('goldens/message_bubble_${me}_default.png'),
      );
    });

    testWidgets('AppMessageBubble — $me italic', (tester) async {
      await tester.pumpWidget(
        goldenScaffold(
          size: const Size(280, 120),
          child: Align(
            alignment:
                isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: AppMessageBubble(
              text: 'Удалено',
              isMine: isMine,
              italic: true,
              dimmed: true,
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(AppMessageBubble),
        matchesGoldenFile('goldens/message_bubble_${me}_italic.png'),
      );
    });

    testWidgets('AppMessageBubble — $me long', (tester) async {
      await tester.pumpWidget(
        goldenScaffold(
          size: const Size(320, 260),
          child: Align(
            alignment:
                isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: AppMessageBubble(
              text:
                  'Длинное сообщение, которое должно перенестись на несколько '
                  'строк, чтобы поверить корректность wrap-логики bubble.',
              isMine: isMine,
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(AppMessageBubble),
        matchesGoldenFile('goldens/message_bubble_${me}_long.png'),
      );
    });
  }
}
