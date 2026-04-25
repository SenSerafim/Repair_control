import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/shared/widgets/widgets.dart';

void main() {
  group('AppTrafficBadge', () {
    testWidgets('рендерит label + dot', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTrafficBadge(
              label: 'По графику',
              semaphore: Semaphore.green,
            ),
          ),
        ),
      );
      expect(find.text('По графику'), findsOneWidget);
    });
  });

  group('AppStepCheckbox', () {
    testWidgets('checked → checkmark icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStepCheckbox(checked: true),
          ),
        ),
      );
      // AnimatedSwitcher шевелит виджет — даём frame.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('unchecked → нет checkmark', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStepCheckbox(checked: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });
  });

  group('AppMessageBubble', () {
    testWidgets('outgoing — bottomRight=4 (асимметричный радиус)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppMessageBubble(text: 'Привет', isMine: true),
          ),
        ),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppMessageBubble),
          matching: find.byType(Container),
        ),
      );
      final dec = container.decoration! as BoxDecoration;
      final br = dec.borderRadius! as BorderRadius;
      expect(br.bottomRight.x, 4);
      expect(br.bottomLeft.x, 16);
    });

    testWidgets('incoming — bottomLeft=4', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppMessageBubble(text: 'Привет', isMine: false),
          ),
        ),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppMessageBubble),
          matching: find.byType(Container),
        ),
      );
      final dec = container.decoration! as BoxDecoration;
      final br = dec.borderRadius! as BorderRadius;
      expect(br.bottomLeft.x, 4);
      expect(br.bottomRight.x, 16);
    });
  });

  group('AppGradientProgressBar', () {
    testWidgets('overspent (>1) → red palette', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppGradientProgressBar(progress: 1.5),
          ),
        ),
      );
      // Smoke — не падает при превышении.
      expect(find.byType(AppGradientProgressBar), findsOneWidget);
    });

    test('ProgressPalette.colors имеет 2 stop-цвета', () {
      for (final p in ProgressPalette.values) {
        expect(p.colors.length, 2);
      }
    });
  });

  group('HeroPalette', () {
    test('console + profile имеют 3 stops', () {
      expect(HeroPalette.console.colors.length, 3);
      expect(HeroPalette.profile.colors.length, 3);
      expect(HeroPalette.console.stops, [0.0, 0.6, 1.0]);
    });
  });
}
