import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/shared/widgets/widgets.dart';

void main() {
  group('AvatarPalette.fromSeed', () {
    test('пустой / null → grey', () {
      expect(AvatarPalette.fromSeed(null), AvatarPalette.grey);
      expect(AvatarPalette.fromSeed(''), AvatarPalette.grey);
    });

    test('стабильна — те же seed → та же палитра', () {
      const seed = 'user-12345';
      final p1 = AvatarPalette.fromSeed(seed);
      final p2 = AvatarPalette.fromSeed(seed);
      expect(p1, p2);
    });

    test('разные seed дают распределение по разным палитрам', () {
      final palettes = <AvatarPalette>{
        for (var i = 0; i < 50; i++)
          AvatarPalette.fromSeed('user-${i * 7}'),
      };
      // Хотя бы 2 разных палитры (распределение работает).
      expect(palettes.length, greaterThanOrEqualTo(2));
    });
  });

  testWidgets('AppAvatar рендерит initials из name', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppAvatar(seed: 'u-1', name: 'Иван Петров'),
        ),
      ),
    );
    // Initials = первые буквы каждого слова, до 2.
    expect(find.text('ИП'), findsOneWidget);
  });

  testWidgets('AppAvatar — fallback "?" для пустого seed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppAvatar(seed: ''),
        ),
      ),
    );
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('AppAvatar — explicit palette переопределяет hash',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppAvatar(
            seed: 'whatever',
            name: 'Test',
            palette: AvatarPalette.green,
          ),
        ),
      ),
    );
    // Smoke — нет крашей при явной палитре.
    expect(find.text('T'), findsOneWidget);
  });
}
