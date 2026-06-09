import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/stages/presentation/_widgets/stage_quick_actions_row.dart';

/// Task 2.2 (TZ-фронт §6): фиксированный ряд «Чат этапа» + «Бюджет этапа»
/// между исполнителями и табами. Виджет состояния не держит — только
/// прокидывает onTap-колбэки в push-навигацию родителя.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required VoidCallback onOpenChat,
    required VoidCallback onOpenBudget,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StageQuickActionsRow(
            onOpenChat: onOpenChat,
            onOpenBudget: onOpenBudget,
          ),
        ),
      ),
    );
  }

  testWidgets('renders both labels "Чат этапа" and "Бюджет этапа"',
      (tester) async {
    await pump(
      tester,
      onOpenChat: () {},
      onOpenBudget: () {},
    );

    expect(find.text('Чат этапа'), findsOneWidget);
    expect(find.text('Бюджет этапа'), findsOneWidget);
  });

  testWidgets('chat button invokes onOpenChat exactly once', (tester) async {
    var chatCalls = 0;
    var budgetCalls = 0;
    await pump(
      tester,
      onOpenChat: () => chatCalls++,
      onOpenBudget: () => budgetCalls++,
    );

    await tester.tap(find.byKey(const ValueKey('stage_quick_chat_button')));
    await tester.pumpAndSettle();

    expect(chatCalls, 1);
    expect(budgetCalls, 0);
  });

  testWidgets('budget button invokes onOpenBudget exactly once',
      (tester) async {
    var chatCalls = 0;
    var budgetCalls = 0;
    await pump(
      tester,
      onOpenChat: () => chatCalls++,
      onOpenBudget: () => budgetCalls++,
    );

    await tester.tap(find.byKey(const ValueKey('stage_quick_budget_button')));
    await tester.pumpAndSettle();

    expect(chatCalls, 0);
    expect(budgetCalls, 1);
  });
}
