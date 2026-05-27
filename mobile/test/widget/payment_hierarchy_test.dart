import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/finance/domain/payment.dart';

/// Hierarchy invariants для упрощённой модели платежей (2026-05-12):
/// платёж = факт передачи денег, statuses/disputes удалены, ребёнок
/// распределённого аванса всегда учитывается в distributedAmount.
void main() {
  Payment payment({
    required String id,
    String? parentId,
    required PaymentKind kind,
    required int amount,
    List<Payment> children = const [],
  }) => Payment.parse({
    'id': id,
    'projectId': 'p-1',
    if (parentId != null) 'parentPaymentId': parentId,
    'kind': kind.apiValue,
    'fromUserId': 'u-1',
    'toUserId': 'u-2',
    'amount': amount,
    'createdAt': '2026-04-01T10:00:00Z',
    'updatedAt': '2026-04-01T10:00:00Z',
    if (children.isNotEmpty)
      'children': [
        for (final c in children)
          {
            'id': c.id,
            'projectId': 'p-1',
            'parentPaymentId': id,
            'kind': c.kind.apiValue,
            'fromUserId': 'u-1',
            'toUserId': 'u-3',
            'amount': c.amount,
            'createdAt': '2026-04-01T10:00:00Z',
            'updatedAt': '2026-04-01T10:00:00Z',
          },
      ],
  });

  group('PaymentX.remainingToDistribute', () {
    test('без детей — равно amount', () {
      final p = payment(
        id: 'p',
        kind: PaymentKind.advance,
        amount: 100000,
      );
      expect(p.amount, 100000);
      expect(p.distributedAmount, 0);
      expect(p.remainingToDistribute, 100000);
    });

    test('remainingToDistribute = amount − sum(children amount)', () {
      final parent = payment(
        id: 'parent',
        kind: PaymentKind.advance,
        amount: 100000,
        children: [
          payment(
            id: 'c1',
            parentId: 'parent',
            kind: PaymentKind.distribution,
            amount: 30000,
          ),
          payment(
            id: 'c2',
            parentId: 'parent',
            kind: PaymentKind.distribution,
            amount: 20000,
          ),
        ],
      );
      expect(parent.distributedAmount, 50000);
      expect(parent.remainingToDistribute, 50000);
    });

    test('remainingToDistribute может стать отрицательным (превышение)', () {
      // Бэк допускает превышение аванса (warning, не блок).
      final parent = payment(
        id: 'parent',
        kind: PaymentKind.advance,
        amount: 100000,
        children: [
          payment(
            id: 'c1',
            parentId: 'parent',
            kind: PaymentKind.distribution,
            amount: 70000,
          ),
          payment(
            id: 'c2',
            parentId: 'parent',
            kind: PaymentKind.distribution,
            amount: 50000,
          ),
        ],
      );
      expect(parent.remainingToDistribute, -20000);
    });

    test('isAdvance / isDistribution маркеры', () {
      final adv = payment(
        id: 'a',
        kind: PaymentKind.advance,
        amount: 1000,
      );
      final dist = payment(
        id: 'd',
        parentId: 'a',
        kind: PaymentKind.distribution,
        amount: 1000,
      );
      expect(adv.isAdvance, isTrue);
      expect(adv.isDistribution, isFalse);
      expect(dist.isDistribution, isTrue);
      expect(dist.isAdvance, isFalse);
    });
  });
}
