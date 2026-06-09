// Task 5.2 (NEWFIX TЗ-фронт §2): drag-and-drop порядка этапов в шаге 3
// wizard'а создания проекта. Шаг 3 рендерит ReorderableListView для
// выбранных пресетов + кастомных этапов и обновляет порядок через onReorder.
//
// Подход: AppButton использует sync-дебаунс по wall-clock DateTime.now(),
// поэтому tester.tap дважды подряд игнорируется fake-async часами widget
// tester'а. Поэтому навигация между шагами идёт через прямой вызов
// onPressed AppButton'а (минуя дебаунс / анимацию PageView'а).
//
// Сценарии:
//   A. После прохождения шагов 1 → 2 → 3 виден ReorderableListView с тремя
//      дефолтными пресетами + секции «Этапы проекта (порядок)» / «Доступные».
//   B. Вызов onReorder из ReorderableListView переставляет элементы:
//      проверяем, что order строк на экране меняется.
//   C. onReorder корректно нормализует newIndex > oldIndex (canonical
//      Flutter convention) — пресет уходит в среднюю позицию, а не в конец.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:repair_control/features/projects/presentation/create_project_screen.dart';
import 'package:repair_control/shared/widgets/widgets.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/projects/new',
    routes: [
      GoRoute(
        path: '/projects/new',
        builder: (_, __) => const CreateProjectScreen(),
      ),
      // Stub-маршрут для context.go после submit. Тест submit не запускает,
      // но GoRouter валидирует маршруты при инициализации.
      GoRoute(
        path: '/projects/:id',
        builder: (_, state) =>
            Scaffold(body: Text('project:${state.pathParameters['id']}')),
      ),
    ],
  );
}

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        routerConfig: _buildRouter(),
        locale: const Locale('ru'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ru'), Locale('en')],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Прыгает к следующему шагу wizard'а минуя AppButton.GestureDetector +
/// его wall-clock дебаунс. AppButton.onPressed напрямую вызывает _next() в
/// state'е CreateProjectScreen → setState(_step += 1) + PageController
/// animate. Затем pumpAndSettle для завершения анимации страницы.
Future<void> _tapNext(WidgetTester tester) async {
  final btnFinder = find.widgetWithText(AppButton, 'Далее');
  expect(btnFinder, findsOneWidget,
      reason: 'Кнопка «Далее» должна быть на экране');
  final btn = tester.widget<AppButton>(btnFinder);
  expect(btn.onPressed, isNotNull, reason: 'Кнопка «Далее» должна быть активна');
  await btn.onPressed!();
  await tester.pumpAndSettle();
}

/// Заполнить поля шага 1 и продвинуться к шагу 3.
Future<void> _goToStep3(WidgetTester tester) async {
  // Step 1: title + address.
  await tester.enterText(
    find.widgetWithText(TextField, 'Например: Квартира на Ленина, 12'),
    'Test Project',
  );
  await tester.pump();
  await tester.enterText(
    find.widgetWithText(TextField, 'ул., дом, квартира'),
    'ул. Тестовая, 1',
  );
  await tester.pumpAndSettle();

  // step 1 → step 2.
  await _tapNext(tester);
  // step 2 → step 3.
  await _tapNext(tester);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru', null);
  });

  testWidgets(
    'A. Шаг 3 рендерит ReorderableListView с дефолтными 3 пресетами',
    (tester) async {
      await _pumpScreen(tester);
      await _goToStep3(tester);

      // Заголовок шага.
      expect(find.text('Этапы'), findsOneWidget);
      // Лейблы секций.
      expect(find.text('ЭТАПЫ ПРОЕКТА (ПОРЯДОК)'), findsOneWidget);
      expect(find.text('ДОСТУПНЫЕ ШАБЛОНЫ'), findsOneWidget);
      // ReorderableListView для выбранных этапов.
      expect(find.byType(ReorderableListView), findsOneWidget);
      // Дефолт: Демонтаж + Электрика + Чистовая отделка.
      expect(find.text('Демонтаж'), findsOneWidget);
      expect(find.text('Электрика'), findsOneWidget);
      expect(find.text('Чистовая отделка'), findsOneWidget);
      // Счётчик «Выбрано: 3».
      expect(find.text('Выбрано: 3'), findsOneWidget);
    },
  );

  testWidgets(
    'B. onReorder меняет порядок выбранных этапов в widget tree',
    (tester) async {
      await _pumpScreen(tester);
      await _goToStep3(tester);

      // Берём onReorder из ReorderableListView и переносим элемент 0 → 3
      // (после последнего). Дефолтный порядок:
      // [Демонтаж, Электрика, Чистовая отделка].
      // После reorder(0, 3): [Электрика, Чистовая отделка, Демонтаж].
      final reorderable = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      reorderable.onReorder(0, 3);
      await tester.pumpAndSettle();

      // Проверяем порядок по геометрии — Y координата сверху-вниз.
      final demolitionY = tester.getTopLeft(find.text('Демонтаж')).dy;
      final electricalY = tester.getTopLeft(find.text('Электрика')).dy;
      final finishingY = tester.getTopLeft(find.text('Чистовая отделка')).dy;

      expect(
        electricalY < finishingY,
        isTrue,
        reason: 'Электрика должна быть выше Чистовой после reorder(0, 3)',
      );
      expect(
        finishingY < demolitionY,
        isTrue,
        reason: 'Чистовая отделка должна быть выше Демонтажа после reorder(0, 3)',
      );
    },
  );

  testWidgets(
    'C. onReorder корректно обрабатывает newIndex > oldIndex',
    (tester) async {
      await _pumpScreen(tester);
      await _goToStep3(tester);

      // Reorder из 0 → 2 (Flutter передаёт newIndex=2 как «после второго
      // элемента»). Реализация в _reorderSelected вычитает 1 → effective
      // index = 1. Дефолт: [Демонтаж, Электрика, Чистовая].
      // После reorder(0, 2): [Электрика, Демонтаж, Чистовая].
      final reorderable = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      reorderable.onReorder(0, 2);
      await tester.pumpAndSettle();

      final demolitionY = tester.getTopLeft(find.text('Демонтаж')).dy;
      final electricalY = tester.getTopLeft(find.text('Электрика')).dy;
      final finishingY = tester.getTopLeft(find.text('Чистовая отделка')).dy;

      expect(
        electricalY < demolitionY,
        isTrue,
        reason: 'Электрика должна быть выше Демонтажа',
      );
      expect(
        demolitionY < finishingY,
        isTrue,
        reason: 'Демонтаж должен остаться выше Чистовой отделки',
      );
    },
  );
}
