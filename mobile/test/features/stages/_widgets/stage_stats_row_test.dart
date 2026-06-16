import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/core/theme/tokens.dart';
import 'package:repair_control/features/stages/presentation/_widgets/stage_stats_row.dart';

/// Task 1.4 (TZ-фронт §6.2): четвёртая ячейка StageStatsRow — счётчик
/// доработок «open/total», а не «Файлов».
void main() {
  testWidgets('StageStatsRow renders "Доработок" cell with X/Y counter', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StageStatsRow(
            progressPct: 42,
            progressColor: AppColors.greenDot,
            stepsDone: 3,
            stepsTotal: 7,
            photosCount: 5,
            reworkOpen: 2,
            reworkTotal: 5,
          ),
        ),
      ),
    );

    expect(find.text('Доработок'), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget);
    // Прочие ячейки сохраняются.
    expect(find.text('42%'), findsOneWidget);
    expect(find.text('Готово'), findsOneWidget);
    expect(find.text('3/7'), findsOneWidget);
    expect(find.text('Шагов'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Фото'), findsOneWidget);
    // Старая ячейка «Файлов» удалена.
    expect(find.text('Файлов'), findsNothing);
  });

  testWidgets('StageStatsRow shows 0/0 when there are no rework approvals', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StageStatsRow(
            progressPct: 10,
            progressColor: AppColors.n400,
            stepsDone: 1,
            stepsTotal: 4,
            photosCount: 0,
            reworkOpen: 0,
            reworkTotal: 0,
          ),
        ),
      ),
    );

    expect(find.text('Доработок'), findsOneWidget);
    // 0/0 встречается только в ячейке «Доработок»: stepsDone/stepsTotal = 1/4.
    expect(find.text('0/0'), findsOneWidget);
  });
}
