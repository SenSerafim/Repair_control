import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:repair_control/core/theme/tokens.dart';
import 'package:repair_control/features/projects/domain/project.dart';
import 'package:repair_control/features/projects/presentation/project_card.dart';

/// NEWFIX-2 §19 — иконка «Заметки проекта» должна жить на карточке
/// проекта в списке (рядом с ⋮). Раньше была только в шапке открытого
/// проекта.
///
/// NEWFIX §1 (Task 5.1) — мини-дашборд: дни до дедлайна · этапы done/total ·
/// сколько «в работе». Этапные счётчики временно `—` (нет в payload).
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru', null);
  });

  Project buildProject({DateTime? plannedEnd}) {
    return Project.parse({
      'id': 'p1',
      'ownerId': 'u1',
      'title': 'Квартира на Ленина',
      'status': 'active',
      'workBudget': 1_000_000_00,
      'materialsBudget': 500_000_00,
      'progressCache': 42,
      'semaphoreCache': 'green',
      'planApproved': false,
      'requiresPlanApproval': false,
      'plannedEnd': plannedEnd?.toUtc().toIso8601String(),
      'createdAt': '2026-04-22T10:00:00Z',
      'updatedAt': '2026-04-22T10:00:00Z',
    });
  }

  testWidgets('ProjectCard exposes a note shortcut with tooltip', (
    tester,
  ) async {
    final project = buildProject();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectCard(project: project, onMenu: () {}),
        ),
      ),
    );

    expect(find.byTooltip('Заметки проекта'), findsOneWidget);
  });

  testWidgets(
    'ProjectCard mini-dashboard renders days-to-deadline + placeholders',
    (tester) async {
      // ~7 дней от сейчас → ожидаем "7д" (с возможной погрешностью на ±1
      // от часового пояса/секунд). Берём диапазон через textContaining.
      final project = buildProject(
        plannedEnd: DateTime.now().add(const Duration(days: 7, hours: 6)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectCard(project: project)),
        ),
      );

      // Этапные счётчики временно `—` — фиксируем контракт «дашборд
      // существует и помечает gaps». Когда payload расширится, тесты
      // ниже пойдут красным и попросят обновить ассерты.
      expect(find.text('—/—'), findsOneWidget);
      expect(find.text('— в работе'), findsOneWidget);

      // Дни — нечётко: 6д/7д из-за времени суток, главное "д" в конце.
      final daysFinder = find.byWidgetPredicate((w) {
        if (w is! Text) return false;
        final t = w.data;
        if (t == null) return false;
        return RegExp(r'^[0-9]+д$').hasMatch(t);
      });
      expect(daysFinder, findsOneWidget);
    },
  );

  testWidgets('ProjectCard mini-dashboard shows overdue label + red color', (
    tester,
  ) async {
    final project = buildProject(
      plannedEnd: DateTime.now().subtract(const Duration(days: 3)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProjectCard(project: project)),
      ),
    );

    // 2 or 3 days overdue (зависит от секунд/часов), главное — формат.
    final overdueFinder = find.byWidgetPredicate((w) {
      if (w is! Text) return false;
      final t = w.data;
      if (t == null) return false;
      return RegExp(r'^[0-9]+д просрочено$').hasMatch(t);
    });
    expect(overdueFinder, findsOneWidget);

    // Цвет — redDot. Берём именно тот Text, который матчит overdue.
    final txt = tester.widget<Text>(overdueFinder);
    expect(txt.style?.color, AppColors.redDot);
  });
}
