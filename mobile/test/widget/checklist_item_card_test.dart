import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/materials/domain/material_request.dart';
import 'package:repair_control/features/materials/presentation/_widgets/checklist_item_card.dart';

MaterialItem _item({bool isBought = false, DateTime? boughtAt}) {
  return MaterialItem(
    id: 'i1',
    requestId: 'r1',
    name: 'Кабель NYM 3×2.5',
    qty: 500,
    unit: 'м',
    pricePerUnit: 84_00,
    totalPrice: 42_000_00,
    isBought: isBought,
    boughtAt: boughtAt,
    createdAt: DateTime(2025, 2, 1),
    updatedAt: DateTime(2025, 2, 1),
  );
}

void main() {
  testWidgets('ChecklistItemCard рендерит "Куплено" статус', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChecklistItemCard(
            item: _item(isBought: true, boughtAt: DateTime(2025, 2, 10, 14, 32)),
            state: ChecklistItemState.bought,
          ),
        ),
      ),
    );
    expect(find.text('Кабель NYM 3×2.5'), findsOneWidget);
    expect(find.text('Куплено'), findsOneWidget);
  });

  testWidgets('ChecklistItemCard рендерит "Ожидает" статус', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChecklistItemCard(
            item: _item(),
            state: ChecklistItemState.pending,
          ),
        ),
      ),
    );
    expect(find.text('Ожидает'), findsOneWidget);
  });

  testWidgets('onEdit-callback срабатывает по тапу на edit-icon',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChecklistItemCard(
            item: _item(),
            state: ChecklistItemState.pending,
            onEdit: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.edit_outlined));
    expect(tapped, isTrue);
  });
}
