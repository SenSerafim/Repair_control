import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/finance/presentation/_widgets/money_summary_chip.dart';

void main() {
  testWidgets('MoneySummaryChip показывает total + 3 секции', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MoneySummaryChip(
            title: 'Итого выплат',
            total: 168_500_00,
            confirmed: 115_000_00,
            pending: 45_000_00,
            selfPurchase: 8_500_00,
          ),
        ),
      ),
    );
    expect(find.text('ИТОГО ВЫПЛАТ'), findsOneWidget);
    expect(find.text('168 500 ₽'), findsOneWidget);
    expect(find.text('Подтверждено: 115 000 ₽'), findsOneWidget);
    expect(find.text('Ожидает: 45 000 ₽'), findsOneWidget);
    expect(find.text('Самозакуп: 8 500 ₽'), findsOneWidget);
  });

  testWidgets('MoneySummaryChip скрывает секцию с amount = 0', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MoneySummaryChip(
            title: 'Итого',
            total: 100_000_00,
            confirmed: 100_000_00,
          ),
        ),
      ),
    );
    expect(find.text('Подтверждено: 100 000 ₽'), findsOneWidget);
    expect(find.textContaining('Ожидает'), findsNothing);
    expect(find.textContaining('Самозакуп'), findsNothing);
  });
}
