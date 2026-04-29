import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repair_control/core/theme/tokens.dart';
import 'package:repair_control/shared/widgets/attempt_badge.dart';
import 'package:repair_control/shared/widgets/scope_badge.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('ScopeBadge', () {
    testWidgets('step → purple palette', (tester) async {
      await tester.pumpWidget(_wrap(const ScopeBadge(
        label: 'Шаг',
        tone: ScopeBadgeTone.step,
      )));
      expect(find.text('Шаг'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.purpleBg);
    });

    testWidgets('extraWork → yellow palette', (tester) async {
      await tester.pumpWidget(_wrap(const ScopeBadge(
        label: 'Доп.работа',
        tone: ScopeBadgeTone.extraWork,
      )));
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.yellowBg);
    });

    testWidgets('stageAccept → brand palette', (tester) async {
      await tester.pumpWidget(_wrap(const ScopeBadge(
        label: 'Приёмка этапа',
        tone: ScopeBadgeTone.stageAccept,
      )));
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.brandLight);
    });

    testWidgets('with icon — renders icon', (tester) async {
      await tester.pumpWidget(_wrap(const ScopeBadge(
        label: 'Электрика',
        tone: ScopeBadgeTone.category,
        icon: Icons.bolt_rounded,
      )));
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
    });
  });

  group('AttemptBadge', () {
    testWidgets('attempt=1 → hidden', (tester) async {
      await tester.pumpWidget(_wrap(const AttemptBadge(attemptNumber: 1)));
      expect(find.text('Попытка 1'), findsNothing);
    });

    testWidgets('attempt=2 → red badge', (tester) async {
      await tester.pumpWidget(_wrap(const AttemptBadge(attemptNumber: 2)));
      expect(find.text('Попытка 2'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.redBg);
    });

    testWidgets('attempt=5 → still red', (tester) async {
      await tester.pumpWidget(_wrap(const AttemptBadge(attemptNumber: 5)));
      expect(find.text('Попытка 5'), findsOneWidget);
    });
  });
}
