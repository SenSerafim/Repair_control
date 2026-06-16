// Task 6.2 (NEWFIX TЗ-2): full-screen «История инструмента».
//
// Подход — оверрайдим `toolCustodyHistoryProvider(toolId)` через
// `.overrideWith(...)` (тот же шаблон, что в user_profile_phone_test.dart).
// Это позволяет проверить три состояния экрана без поднятия dio/socket-стека.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/tools/application/tools_controller.dart';
import 'package:repair_control/features/tools/domain/tool.dart';
import 'package:repair_control/features/tools/presentation/tool_custody_history_screen.dart';

PublicUser _user(String id, String first, String last) =>
    PublicUser(id: id, firstName: first, lastName: last);

ToolCustodyEvent _event({
  required String id,
  required PublicUser holder,
  PublicUser? previous,
  String? note,
  DateTime? at,
}) {
  return ToolCustodyEvent(
    id: id,
    toolItemId: 't1',
    projectId: 'p1',
    holderId: holder.id,
    previousHolderId: previous?.id,
    note: note,
    holder: holder,
    previousHolder: previous,
    createdAt: at ?? DateTime.utc(2026, 6, 1, 9, 0),
  );
}

Widget _harness({required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: ToolCustodyHistoryScreen(toolId: 't1', toolName: 'Перфоратор'),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 6.2 · ToolCustodyHistoryScreen', () {
    testWidgets('рендерит карточку на каждое событие из репозитория', (
      tester,
    ) async {
      final foreman = _user('u-foreman', 'Иван', 'Бригадиров');
      final master = _user('u-master', 'Пётр', 'Мастеров');
      final customer = _user('u-customer', 'Сергей', 'Заказчиков');

      final events = [
        _event(id: 'e1', holder: foreman),
        _event(
          id: 'e2',
          holder: master,
          previous: foreman,
          at: DateTime.utc(2026, 6, 2, 12, 30),
        ),
        _event(
          id: 'e3',
          holder: customer,
          previous: master,
          note: 'Передал для приёмки',
          at: DateTime.utc(2026, 6, 3, 18, 15),
        ),
      ];

      await tester.pumpWidget(
        _harness(
          overrides: [
            toolCustodyHistoryProvider(
              't1',
            ).overrideWith((ref) async => events),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Подзаголовок — имя инструмента из конструктора.
      expect(find.text('Перфоратор'), findsOneWidget);

      // Первое событие — initial, бейдж «СТАРТ»; остальные — «ПЕРЕДАЧА».
      expect(find.text('СТАРТ'), findsOneWidget);
      expect(find.text('ПЕРЕДАЧА'), findsNWidgets(2));

      // Имена участников отрендерены: «previous → holder».
      expect(find.textContaining('Иван Бригадиров'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Пётр Мастеров'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Сергей Заказчиков'), findsAtLeastNWidgets(1));

      // Note выведена в кавычках, italic-плашке.
      expect(find.text('«Передал для приёмки»'), findsOneWidget);

      // Список присутствует и содержит ровно (events × 2 - 1) дочерних
      // элементов через separator: 3 события → 5 элементов в делегате.
      final listFinder = find.byKey(
        const ValueKey('tool_custody_history_list'),
      );
      expect(listFinder, findsOneWidget);
      final listView = tester.widget<ListView>(listFinder);
      final delegate = listView.childrenDelegate as SliverChildBuilderDelegate;
      // ListView.separated: для N items даёт N + (N-1) детей в делегате.
      expect(delegate.childCount, 3 * 2 - 1);

      // Combined-badge cross-check: всего 3 события — 1 «СТАРТ» + 2
      // «ПЕРЕДАЧА» = 3 карточки.
      expect(
        find.text('СТАРТ').evaluate().length +
            find.text('ПЕРЕДАЧА').evaluate().length,
        3,
      );
    });

    testWidgets('пустой список → AppEmptyState с «Нет истории»', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          overrides: [
            toolCustodyHistoryProvider(
              't1',
            ).overrideWith((ref) async => const <ToolCustodyEvent>[]),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Нет истории'), findsOneWidget);
      // Cards с событиями не должно быть.
      expect(find.text('СТАРТ'), findsNothing);
      expect(find.text('ПЕРЕДАЧА'), findsNothing);
    });

    testWidgets('ошибка репозитория → AppErrorState с безопасным subtitle '
        '(никакого e.toString())', (tester) async {
      await tester.pumpWidget(
        _harness(
          overrides: [
            toolCustodyHistoryProvider('t1').overrideWith(
              (ref) async =>
                  throw Exception('boom-leaked-internal-stack-trace'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить историю'), findsOneWidget);
      // Внутренний текст исключения не должен утечь в UI.
      expect(
        find.textContaining('boom-leaked-internal-stack-trace'),
        findsNothing,
      );
      // Safe subtitle — статичная подсказка.
      expect(find.textContaining('Проверьте подключение'), findsOneWidget);
    });

    testWidgets('fallback: если PublicUser отсутствует, рендерим обрезанный id '
        '(#abcdef)', (tester) async {
      final events = [
        ToolCustodyEvent(
          id: 'e1',
          toolItemId: 't1',
          projectId: 'p1',
          holderId: 'abcdef1234567890',
          createdAt: DateTime.utc(2026, 6, 1, 9, 0),
        ),
      ];

      await tester.pumpWidget(
        _harness(
          overrides: [
            toolCustodyHistoryProvider(
              't1',
            ).overrideWith((ref) async => events),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 6 первых символов id с префиксом #.
      expect(find.textContaining('#abcdef'), findsAtLeastNWidgets(1));
    });
  });
}
