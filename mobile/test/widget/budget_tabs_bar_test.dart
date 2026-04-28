import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/finance/presentation/_widgets/budget_tabs_bar.dart';

void main() {
  testWidgets('BudgetTabsBar показывает 3 таба + badge на Выплатах',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BudgetTabsBar(
            selected: BudgetTab.payments,
            onChanged: (_) {},
            paymentsCount: 5,
          ),
        ),
      ),
    );
    expect(find.text('Выплаты'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('По этапам'), findsOneWidget);
    expect(find.text('Материалы'), findsOneWidget);
  });

  testWidgets('Tap по табу вызывает onChanged', (tester) async {
    BudgetTab selected = BudgetTab.payments;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, setState) => BudgetTabsBar(
              selected: selected,
              onChanged: (t) => setState(() => selected = t),
              paymentsCount: 0,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Материалы'));
    await tester.pump();
    expect(selected, BudgetTab.materials);
  });

  testWidgets('Без выплат badge не отображается', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BudgetTabsBar(
            selected: BudgetTab.payments,
            onChanged: (_) {},
            paymentsCount: 0,
          ),
        ),
      ),
    );
    expect(find.text('0'), findsNothing);
  });
}
