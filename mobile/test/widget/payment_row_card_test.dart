import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/finance/domain/payment.dart';
import 'package:repair_control/features/finance/presentation/_widgets/payment_row_card.dart';

Payment _payment({
  PaymentKind kind = PaymentKind.advance,
  String? comment,
}) {
  return Payment(
    id: 'p1',
    projectId: 'pr1',
    kind: kind,
    fromUserId: 'u-from',
    toUserId: 'u-to',
    amount: 50_000_00,
    comment: comment,
    createdAt: DateTime(2025, 1, 15),
    updatedAt: DateTime(2025, 1, 15),
  );
}

void main() {
  testWidgets('PaymentRowCard рендерит сумму и имя получателя', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentRowCard(
            payment: _payment(),
            recipientName: 'Петров С.',
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('50 000 ₽'), findsOneWidget);
    expect(find.textContaining('Петров С.'), findsOneWidget);
  });

  testWidgets('PaymentRowCard distribution-kind рендерится без статус-pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentRowCard(
            payment: _payment(kind: PaymentKind.distribution),
            recipientName: 'Иванов А.',
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.textContaining('Распределение'), findsOneWidget);
  });

  testWidgets('PaymentRowCard вызывает onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentRowCard(
            payment: _payment(),
            recipientName: 'X',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(PaymentRowCard));
    expect(tapped, isTrue);
  });
}
