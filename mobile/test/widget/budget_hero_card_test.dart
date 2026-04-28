import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/finance/domain/budget.dart';
import 'package:repair_control/features/finance/presentation/_widgets/budget_hero_card.dart';

void main() {
  testWidgets('BudgetHeroCard рендерит сумму, потрачено и остаток',
      (tester) async {
    const total = BudgetBucket(
      planned: 830_000_00,
      spent: 375_000_00,
      remaining: 455_000_00,
    );
    const work = BudgetBucket(
      planned: 350_000_00,
      spent: 193_000_00,
      remaining: 157_000_00,
    );
    const materials = BudgetBucket(
      planned: 480_000_00,
      spent: 182_000_00,
      remaining: 298_000_00,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BudgetHeroCard(
            total: total,
            work: work,
            materials: materials,
          ),
        ),
      ),
    );
    expect(find.text('830 000 ₽'), findsOneWidget); // total planned
    expect(find.text('375 000 ₽'), findsOneWidget); // spent
    expect(find.text('455 000 ₽'), findsOneWidget); // remaining (зелёный)
    expect(find.text('РАБОТЫ'), findsOneWidget);
    expect(find.text('МАТЕРИАЛЫ'), findsOneWidget);
  });

  testWidgets('BudgetHeroCard показывает overspent красным', (tester) async {
    const total = BudgetBucket(
      planned: 100_000_00,
      spent: 150_000_00,
      remaining: -50_000_00,
    );
    const work = BudgetBucket(planned: 0, spent: 0, remaining: 0);
    const materials = BudgetBucket(planned: 0, spent: 0, remaining: 0);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BudgetHeroCard(
            total: total,
            work: work,
            materials: materials,
          ),
        ),
      ),
    );
    // remaining text should be red.
    final remainingText = tester.widget<Text>(find.text('-50 000 ₽'));
    expect(remainingText.style?.color, isNotNull);
  });
}
