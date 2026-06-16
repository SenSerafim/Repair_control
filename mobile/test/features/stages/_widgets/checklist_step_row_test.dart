// Task 3.3 (TZ-фронт §7.4): pill «На согласование» под названием шага, когда
// у шага открыто согласование scope=step. Источник истины — родитель
// (StageChecklistTab), сюда приезжает простой `hasPendingApproval` флаг.
//
// Сам провайдер approvals здесь не дёргаем — это unit-level тест строки.
// Покрытие интеграции с провайдером — на уровне StageChecklistTab (не входит
// в задачу 3.3, см. план §2.x).
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:repair_control/features/stages/presentation/_widgets/checklist_step_row.dart';
import 'package:repair_control/features/steps/domain/step.dart';

Step _step() => Step.parse({
  'id': 'step-1',
  'stageId': 'stage-1',
  'title': 'Демонтаж старой плитки',
  'orderIndex': 0,
  'type': 'regular',
  'status': 'pending',
  'authorId': 'u-1',
  'createdAt': '2026-04-01T10:00:00Z',
  'updatedAt': '2026-04-01T10:00:00Z',
});

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUpAll(() async {
    // Внутри _ChecklistStepRowState.build вызывается DateFormat('d MMM', 'ru')
    // безусловно (даже если completedAt=null). Без инициализации локали тест
    // падает LocaleDataException ещё до проверок.
    await initializeDateFormatting('ru');
  });

  testWidgets('ChecklistStepRow показывает pill «На согласование» при '
      'hasPendingApproval=true', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ChecklistStepRow(
          step: _step(),
          hasPendingApproval: true,
          onTap: () {},
          onToggleDone: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('На согласование'), findsOneWidget);
  });

  testWidgets(
    'ChecklistStepRow не показывает pill при hasPendingApproval=false',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ChecklistStepRow(step: _step(), onTap: () {}, onToggleDone: () {}),
        ),
      );
      await tester.pump();

      expect(find.text('На согласование'), findsNothing);
    },
  );
}
