import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/materials/presentation/_widgets/purchase_progress_chip.dart';

void main() {
  testWidgets('PurchaseProgressChip показывает N/M', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PurchaseProgressChip(bought: 2, total: 3),
        ),
      ),
    );
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('ПРОГРЕСС ЗАКУПКИ'), findsOneWidget);
  });

  testWidgets('PurchaseProgressChip handles total=0 без NaN', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PurchaseProgressChip(bought: 0, total: 0),
        ),
      ),
    );
    expect(find.text('0/0'), findsOneWidget);
  });
}
