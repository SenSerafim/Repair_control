import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/shared/widgets/app_house_progress.dart';
import 'package:repair_control/shared/widgets/celebration/_house_segments.dart';
import 'package:repair_control/shared/widgets/status_pill.dart';

/// House widget активно использует `flutter_animate` (smoke + sparkles),
/// которые внутри планируют `Future.delayed` через FakeAsync. flutter_animate
/// не отменяет эти Future при dispose (`_delayed.ignore()` не равно cancel).
/// Чтобы FakeAsync не упал на `'!timersPending'`, после анмаунта
/// прокручиваем фейковое время на 1.5 сек — таймеры срабатывают
/// (но callbacks no-op на disposed state).
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1500));
}

Future<void> pumpHouse(
  WidgetTester tester, {
  required int percent,
  required Semaphore semaphore,
  int bouncePulse = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppHouseProgress(
            percent: percent,
            semaphore: semaphore,
            subtitle: 'Этап $percent%',
            bouncePulse: bouncePulse,
          ),
        ),
      ),
    ),
  );
  // Используем pump(duration), а не pumpAndSettle, т.к. при 100%
  // активна бесконечная pulse-анимация (S17 геймификация).
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('AppHouseProgress не падает на 0/50/100', (tester) async {
    await pumpHouse(tester, percent: 0, semaphore: Semaphore.plan);
    expect(find.text('0%'), findsOneWidget);

    await pumpHouse(tester, percent: 50, semaphore: Semaphore.yellow);
    expect(find.text('50%'), findsOneWidget);

    await pumpHouse(tester, percent: 100, semaphore: Semaphore.green);
    expect(find.text('100%'), findsOneWidget);

    await _teardown(tester);
  });

  testWidgets('AppHouseProgress отражает все 5 цветов', (tester) async {
    for (final s in Semaphore.values) {
      await pumpHouse(tester, percent: 42, semaphore: s);
      expect(find.text('42%'), findsOneWidget);
    }
    await _teardown(tester);
  });

  testWidgets('На 30% видны фундамент + цоколь, нет стен 1F',
      (tester) async {
    await pumpHouse(tester, percent: 30, semaphore: Semaphore.red);
    // Дать слоям дойти до конечного opacity.
    await tester.pump(const Duration(milliseconds: 500));

    // Все 9 классов всегда есть в дереве (показ управляется visible).
    final fnd = tester.widget<HouseFoundation>(find.byType(HouseFoundation));
    final socle = tester.widget<HouseSocle>(find.byType(HouseSocle));
    final w1 = tester.widget<HouseWalls1F>(find.byType(HouseWalls1F));

    expect(fnd.visible, isTrue);
    expect(socle.visible, isTrue);
    expect(w1.visible, isFalse);

    await _teardown(tester);
  });

  testWidgets('На 100% все 9 слоёв visible + sparkles', (tester) async {
    await pumpHouse(tester, percent: 100, semaphore: Semaphore.green);
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      tester.widget<HouseFoundation>(find.byType(HouseFoundation)).visible,
      isTrue,
    );
    expect(
      tester.widget<HouseSocle>(find.byType(HouseSocle)).visible,
      isTrue,
    );
    expect(
      tester.widget<HouseWalls1F>(find.byType(HouseWalls1F)).visible,
      isTrue,
    );
    expect(
      tester.widget<HouseCeiling>(find.byType(HouseCeiling)).visible,
      isTrue,
    );
    expect(
      tester.widget<HouseWalls2F>(find.byType(HouseWalls2F)).visible,
      isTrue,
    );
    expect(
      tester.widget<HouseRafters>(find.byType(HouseRafters)).visible,
      isTrue,
    );
    expect(
      tester.widget<HouseRoof>(find.byType(HouseRoof)).visible,
      isTrue,
    );
    expect(
      tester.widget<HouseFacade>(find.byType(HouseFacade)).visible,
      isTrue,
    );
    expect(
      tester.widget<HouseWindows>(find.byType(HouseWindows)).visible,
      isTrue,
    );

    // Sparkles появляются только на 100%.
    expect(find.byType(HouseSparkles), findsOneWidget);

    await _teardown(tester);
  });

  testWidgets('На <100% sparkles не рендерятся', (tester) async {
    await pumpHouse(tester, percent: 99, semaphore: Semaphore.yellow);
    expect(find.byType(HouseSparkles), findsNothing);
    await _teardown(tester);
  });

  testWidgets('Изменение bouncePulse запускает Transform.scale-анимацию',
      (tester) async {
    await pumpHouse(tester, percent: 60, semaphore: Semaphore.green);

    // bouncePulse = 0 → ни одна frame-callback не активна на bounce.
    final pendingBefore = tester.binding.transientCallbackCount;

    // Триггерим bounce: изменение bouncePulse.
    await pumpHouse(
      tester,
      percent: 60,
      semaphore: Semaphore.green,
      bouncePulse: 1,
    );
    // После старта bounce-анимации регистрируется новый transient callback.
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      tester.binding.transientCallbackCount,
      greaterThan(pendingBefore),
      reason: 'bounce-controller должен запустить анимацию-кадр',
    );

    // Дать анимации отыграть до конца, чтобы не остались pending timers.
    await tester.pump(const Duration(milliseconds: 800));
    await _teardown(tester);
  });
}
