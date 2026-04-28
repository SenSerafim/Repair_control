import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/finance/domain/payment.dart';
import 'package:repair_control/features/finance/presentation/_widgets/payment_row_card.dart';

Payment _payment({
  required PaymentStatus status,
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
    status: status,
    comment: comment,
    createdAt: DateTime(2025, 1, 15),
    updatedAt: DateTime(2025, 1, 15),
  );
}

void main() {
  testWidgets('PaymentRowCard рендерит сумму, имя получателя и статус',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentRowCard(
            payment: _payment(status: PaymentStatus.confirmed),
            recipientName: 'Петров С.',
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('50 000 ₽'), findsOneWidget);
    expect(find.text('Подтверждено'), findsOneWidget);
    expect(find.textContaining('Петров С.'), findsOneWidget);
  });

  testWidgets('PaymentRowCard в pending — иконка часы, цвет статуса жёлтый',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentRowCard(
            payment: _payment(status: PaymentStatus.pending),
            recipientName: 'Иванов А.',
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('Ожидает'), findsOneWidget);
  });

  testWidgets('PaymentRowCard вызывает onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentRowCard(
            payment: _payment(status: PaymentStatus.confirmed),
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
