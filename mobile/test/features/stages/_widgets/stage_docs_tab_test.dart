// Task 7.2 (NEWFIX §13 / план Q3): таб «Докум.» на StageDetailScreen.
//
// Проверяем:
//   A. По умолчанию активен сегмент «Фото» — секция фото видна,
//      секция документов скрыта.
//   B. Тап по сегменту «Документы» переключает рендер: появляется
//      секция документов, секция фото исчезает.
//   C. Документы группируются по `Document.stepId`: для двух разных
//      шагов появляются два заголовка «Шаг N: <title>».
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:repair_control/features/documents/application/documents_controller.dart';
import 'package:repair_control/features/documents/domain/document.dart';
import 'package:repair_control/features/stages/presentation/_widgets/stage_docs_tab.dart';
import 'package:repair_control/features/steps/application/steps_controller.dart';
import 'package:repair_control/features/steps/domain/step.dart' as dm;

dm.Step _step({
  required String id,
  required String title,
  int orderIndex = 0,
  int photosCount = 0,
}) => dm.Step(
  id: id,
  stageId: 's1',
  title: title,
  orderIndex: orderIndex,
  type: dm.StepType.regular,
  status: dm.StepStatus.pending,
  authorId: 'u_foreman',
  photosCount: photosCount,
  createdAt: DateTime(2026, 6, 1),
  updatedAt: DateTime(2026, 6, 1),
);

Document _doc({
  required String id,
  required String title,
  String? stepId,
  DocumentCategory category = DocumentCategory.other,
}) => Document(
  id: id,
  projectId: 'p1',
  stageId: 's1',
  stepId: stepId,
  category: category,
  title: title,
  fileKey: 'k/$id',
  mimeType: 'application/pdf',
  sizeBytes: 2048,
  uploadedBy: 'u1',
  confirmed: true,
  createdAt: DateTime(2026, 6, 1),
  updatedAt: DateTime(2026, 6, 1),
);

Widget _wrap({
  required List<dm.Step> steps,
  required List<Document> docs,
}) {
  return ProviderScope(
    overrides: [
      stepsControllerProvider.overrideWith(() => _StubStepsCtrl(steps)),
      documentsByStageProvider((
        projectId: 'p1',
        stageId: 's1',
      )).overrideWith((ref) async => docs),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: StageDocsTab(projectId: 'p1', stageId: 's1'),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    // _DocRow рендерит DateFormat('d MMM y', 'ru'). Без initializeDateFormatting
    // тесты падают LocaleDataException.
    await initializeDateFormatting('ru');
  });

  testWidgets(
    'A. По умолчанию активен сегмент «Фото»: секция фото видна, '
    'документов — нет',
    (tester) async {
      final steps = [
        _step(id: 'st1', title: 'Поклейка обоев', photosCount: 3),
        _step(id: 'st2', title: 'Покраска стен', photosCount: 2),
      ];
      final docs = [_doc(id: 'd1', title: 'Смета.pdf')];

      await tester.pumpWidget(_wrap(steps: steps, docs: docs));
      await tester.pumpAndSettle();

      // Сегмент-переключатель присутствует.
      expect(
        find.byKey(const ValueKey('stage_docs_view_toggle')),
        findsOneWidget,
      );

      // Видна секция фото с подзаголовком и аггрегацией.
      expect(
        find.byKey(const ValueKey('stage_docs_photos_section')),
        findsOneWidget,
      );
      expect(find.text('ФОТО ШАГОВ · 5'), findsOneWidget);

      // Секция документов скрыта.
      expect(
        find.byKey(const ValueKey('stage_docs_files_section')),
        findsNothing,
      );
      expect(find.text('Смета.pdf'), findsNothing);
    },
  );

  testWidgets(
    'B. Тап по «Документы» показывает секцию документов и скрывает фото',
    (tester) async {
      final steps = [
        _step(id: 'st1', title: 'Поклейка обоев', photosCount: 3),
      ];
      final docs = [_doc(id: 'd1', title: 'Смета.pdf', stepId: 'st1')];

      await tester.pumpWidget(_wrap(steps: steps, docs: docs));
      await tester.pumpAndSettle();

      // Базовое состояние — фото видны.
      expect(
        find.byKey(const ValueKey('stage_docs_photos_section')),
        findsOneWidget,
      );

      // Тапаем на сегмент «Документы».
      await tester.tap(find.text('Документы'));
      await tester.pumpAndSettle();

      // Теперь секция документов видна, фото скрыты.
      expect(
        find.byKey(const ValueKey('stage_docs_files_section')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('stage_docs_photos_section')),
        findsNothing,
      );
      expect(find.text('ФАЙЛЫ · 1'), findsOneWidget);
      expect(find.text('Смета.pdf'), findsOneWidget);
    },
  );

  testWidgets(
    'C. Документы двух разных шагов рендерят два заголовка-группы',
    (tester) async {
      final steps = [
        _step(id: 'st1', title: 'Поклейка обоев', orderIndex: 0),
        _step(id: 'st2', title: 'Покраска стен', orderIndex: 1),
      ];
      final docs = [
        _doc(id: 'd1', title: 'Смета шаг 1.pdf', stepId: 'st1'),
        _doc(id: 'd2', title: 'Фото шаг 1.pdf', stepId: 'st1'),
        _doc(id: 'd3', title: 'Акт шаг 2.pdf', stepId: 'st2'),
      ];

      await tester.pumpWidget(_wrap(steps: steps, docs: docs));
      await tester.pumpAndSettle();

      // Переключаемся на документы.
      await tester.tap(find.text('Документы'));
      await tester.pumpAndSettle();

      // Видим два заголовка групп (uppercase).
      expect(
        find.text('ШАГ 1: ПОКЛЕЙКА ОБОЕВ'),
        findsOneWidget,
      );
      expect(
        find.text('ШАГ 2: ПОКРАСКА СТЕН'),
        findsOneWidget,
      );

      // Файлы всех групп присутствуют.
      expect(find.text('Смета шаг 1.pdf'), findsOneWidget);
      expect(find.text('Фото шаг 1.pdf'), findsOneWidget);
      expect(find.text('Акт шаг 2.pdf'), findsOneWidget);
    },
  );
}

/// Стаб для StepsController. Возвращает заранее заданный список без
/// сортировки — тест строит порядок сам.
class _StubStepsCtrl extends StepsController {
  _StubStepsCtrl(this._items);

  final List<dm.Step> _items;

  @override
  Future<List<dm.Step>> build(StepsKey key) async => _items;
}
