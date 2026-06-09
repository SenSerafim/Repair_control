// Task 3.1 + 3.2 (NEWFIX-3 §3): drag-reorder + поиск в чек-листе этапа.
//
// Проверяем:
//   A. ReorderableListView виден, когда поиск пуст и есть права на add.
//   B. Поиск фильтрует список (case-insensitive по title).
//   C. При активном поиске drag отключается — рендерится обычный ListView.
//   D. Когда `onAddStep == null` (нет прав на step.manage) — drag тоже
//      отключён.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:repair_control/features/approvals/application/approvals_controller.dart';
import 'package:repair_control/features/stages/domain/stage.dart';
import 'package:repair_control/features/stages/presentation/_widgets/checklist_step_row.dart';
import 'package:repair_control/features/stages/presentation/_widgets/stage_checklist_tab.dart';
import 'package:repair_control/features/stages/presentation/stage_widgets.dart';
import 'package:repair_control/features/steps/application/steps_controller.dart';
import 'package:repair_control/features/steps/domain/step.dart' as dm;

Stage _stage() => Stage(
  id: 's1',
  projectId: 'p1',
  title: 'Демонтаж',
  orderIndex: 0,
  status: StageStatus.active,
  pauseDurationMs: 0,
  workBudget: 0,
  materialsBudget: 0,
  foremanIds: const ['u_foreman'],
  progressCache: 0,
  planApproved: true,
  createdAt: DateTime(2026, 6, 1),
  updatedAt: DateTime(2026, 6, 1),
);

dm.Step _step({
  required String id,
  required String title,
  int orderIndex = 0,
  dm.StepStatus status = dm.StepStatus.pending,
}) => dm.Step(
  id: id,
  stageId: 's1',
  title: title,
  orderIndex: orderIndex,
  type: dm.StepType.regular,
  status: status,
  authorId: 'u_foreman',
  createdAt: DateTime(2026, 6, 1),
  updatedAt: DateTime(2026, 6, 1),
);

Widget _wrap(
  Widget body, {
  required List<dm.Step> steps,
  VoidCallback? onAddStep,
}) {
  return ProviderScope(
    overrides: [
      stepsControllerProvider.overrideWith(() => _StubStepsCtrl(steps)),
      approvalsControllerProvider.overrideWith(
        () => _StubApprovalsCtrl(
          const ApprovalsBuckets(pending: [], history: []),
        ),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: StageChecklistTab(
          stage: _stage(),
          display: StageDisplayStatus.active,
          onStepTap: (_) {},
          onAddStep: onAddStep,
          onToggleStep: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    // ChecklistStepRow использует DateFormat('d MMM', 'ru'). Без
    // initializeDateFormatting тесты падают LocaleDataException.
    await initializeDateFormatting('ru');
  });

  testWidgets(
    'A. Drag-режим: ReorderableListView рендерится, виден add-CTA',
    (tester) async {
      final steps = [
        _step(id: 'st1', title: 'Поклейка обоев', orderIndex: 0),
        _step(id: 'st2', title: 'Покраска стен', orderIndex: 1),
        _step(id: 'st3', title: 'Укладка плитки', orderIndex: 2),
      ];
      await tester.pumpWidget(
        _wrap(const SizedBox.shrink(), steps: steps, onAddStep: () {}),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReorderableListView), findsOneWidget);
      // Не упало в plain-режим, ListView.builder отсутствует на верхнем уровне.
      expect(find.byType(ChecklistStepRow), findsNWidgets(3));
      expect(find.text('Поклейка обоев'), findsOneWidget);
      expect(find.text('Покраска стен'), findsOneWidget);
      expect(find.text('Укладка плитки'), findsOneWidget);
      // Кнопка «Добавить шаг» отрендерилась (footer Column в drag-режиме).
      expect(find.text('Добавить шаг'), findsOneWidget);
    },
  );

  testWidgets(
    'B. Поиск фильтрует шаги по title (case-insensitive)',
    (tester) async {
      final steps = [
        _step(id: 'st1', title: 'Поклейка обоев', orderIndex: 0),
        _step(id: 'st2', title: 'Покраска стен', orderIndex: 1),
        _step(id: 'st3', title: 'Укладка плитки', orderIndex: 2),
      ];
      await tester.pumpWidget(
        _wrap(const SizedBox.shrink(), steps: steps, onAddStep: () {}),
      );
      await tester.pumpAndSettle();

      // Ввод "ПОКЛЕЙ" в UPPER — case-insensitive contains должен сматчить
      // "Поклейка обоев" и больше ничего.
      await tester.enterText(find.byType(TextField), 'ПОКЛЕЙ');
      await tester.pumpAndSettle();

      expect(find.byType(ChecklistStepRow), findsOneWidget);
      expect(find.text('Поклейка обоев'), findsOneWidget);
      expect(find.text('Покраска стен'), findsNothing);
      expect(find.text('Укладка плитки'), findsNothing);
    },
  );

  testWidgets(
    'C. При активном поиске ReorderableListView заменяется на обычный ListView',
    (tester) async {
      final steps = [
        _step(id: 'st1', title: 'Поклейка обоев', orderIndex: 0),
        _step(id: 'st2', title: 'Покраска стен', orderIndex: 1),
      ];
      await tester.pumpWidget(
        _wrap(const SizedBox.shrink(), steps: steps, onAddStep: () {}),
      );
      await tester.pumpAndSettle();

      // До поиска — drag-режим.
      expect(find.byType(ReorderableListView), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'покраска');
      await tester.pumpAndSettle();

      // Drag отключён, осталась только одна совпавшая карточка.
      expect(find.byType(ReorderableListView), findsNothing);
      expect(find.byType(ChecklistStepRow), findsOneWidget);
      expect(find.text('Покраска стен'), findsOneWidget);
    },
  );

  testWidgets(
    'D. Без права step.manage (onAddStep==null) drag отключён',
    (tester) async {
      final steps = [
        _step(id: 'st1', title: 'Поклейка обоев', orderIndex: 0),
        _step(id: 'st2', title: 'Покраска стен', orderIndex: 1),
      ];
      await tester.pumpWidget(
        _wrap(const SizedBox.shrink(), steps: steps),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReorderableListView), findsNothing);
      expect(find.byType(ChecklistStepRow), findsNWidgets(2));
      // Add-CTA не показывается.
      expect(find.text('Добавить шаг'), findsNothing);
    },
  );

  testWidgets(
    'Empty-state с шагами + поиск без совпадений → «Ничего не найдено»',
    (tester) async {
      final steps = [
        _step(id: 'st1', title: 'Поклейка обоев', orderIndex: 0),
      ];
      await tester.pumpWidget(
        _wrap(const SizedBox.shrink(), steps: steps, onAddStep: () {}),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzz_no_match');
      await tester.pumpAndSettle();

      expect(find.text('Ничего не найдено'), findsOneWidget);
      expect(find.byType(ChecklistStepRow), findsNothing);
    },
  );
}

/// Стаб для StepsController. Возвращает заранее заданный список —
/// порядок не сортируем, тесты строят список в требуемом порядке сами.
class _StubStepsCtrl extends StepsController {
  _StubStepsCtrl(this._items);

  final List<dm.Step> _items;

  @override
  Future<List<dm.Step>> build(StepsKey key) async => _items;
}

/// Стаб для ApprovalsController — для теста чек-листа достаточно
/// пустых buckets.
class _StubApprovalsCtrl extends ApprovalsController {
  _StubApprovalsCtrl(this._b);

  final ApprovalsBuckets _b;

  @override
  Future<ApprovalsBuckets> build(String projectId) async => _b;
}
