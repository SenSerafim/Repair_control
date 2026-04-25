import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/finance/domain/payment.dart';

/// Phase 5 acceptance: hierarchy / dispute / extraWorks инварианты.
void main() {
  Payment payment({
    required String id,
    String? parentId,
    required PaymentKind kind,
    required PaymentStatus status,
    required int amount,
    int? resolvedAmount,
    List<Payment> children = const [],
  }) =>
      Payment.parse({
        'id': id,
        'projectId': 'p-1',
        if (parentId != null) 'parentPaymentId': parentId,
        'kind': kind.apiValue,
        'fromUserId': 'u-1',
        'toUserId': 'u-2',
        'amount': amount,
        if (resolvedAmount != null) 'resolvedAmount': resolvedAmount,
        'status': status.apiValue,
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
                if (c.resolvedAmount != null)
                  'resolvedAmount': c.resolvedAmount,
                'status': c.status.apiValue,
                'createdAt': '2026-04-01T10:00:00Z',
                'updatedAt': '2026-04-01T10:00:00Z',
              },
          ],
      });

  group('PaymentX.effectiveAmount + remainingToDistribute', () {
    test('effectiveAmount = amount если resolvedAmount=null', () {
      final p = payment(
        id: 'p',
        kind: PaymentKind.advance,
        status: PaymentStatus.confirmed,
        amount: 100000,
      );
      expect(p.effectiveAmount, 100000);
    });

    test('effectiveAmount = resolvedAmount если задан', () {
      final p = payment(
        id: 'p',
        kind: PaymentKind.advance,
        status: PaymentStatus.resolved,
        amount: 100000,
        resolvedAmount: 80000,
      );
      expect(p.effectiveAmount, 80000);
    });

    test('remainingToDistribute = effective - sum(active children effective)',
        () {
      final parent = payment(
        id: 'parent',
        kind: PaymentKind.advance,
        status: PaymentStatus.confirmed,
        amount: 100000,
        children: [
          payment(
            id: 'c1',
            parentId: 'parent',
            kind: PaymentKind.distribution,
            status: PaymentStatus.confirmed,
            amount: 30000,
          ),
          payment(
            id: 'c2',
            parentId: 'parent',
            kind: PaymentKind.distribution,
            status: PaymentStatus.pending,
            amount: 20000,
          ),
        ],
      );
      expect(parent.distributedAmount, 50000);
      expect(parent.remainingToDistribute, 50000);
    });

    test('cancelled child НЕ учитывается в distributedAmount', () {
      final parent = payment(
        id: 'parent',
        kind: PaymentKind.advance,
        status: PaymentStatus.confirmed,
        amount: 100000,
        children: [
          payment(
            id: 'c1',
            parentId: 'parent',
            kind: PaymentKind.distribution,
            status: PaymentStatus.confirmed,
            amount: 30000,
          ),
          payment(
            id: 'c2',
            parentId: 'parent',
            kind: PaymentKind.distribution,
            status: PaymentStatus.cancelled,
            amount: 50000,
          ),
        ],
      );
      expect(parent.activeChildren.length, 1);
      expect(parent.distributedAmount, 30000);
      expect(parent.remainingToDistribute, 70000);
    });

    test(
        'remainingToDistribute учитывает resolvedAmount '
        'и родителя, и детей', () {
      // Родитель: 100k → resolved 80k. Дети: 30k confirmed + 20k → resolved 15k.
      // Доступно: 80 - (30 + 15) = 35k.
      final parent = payment(
        id: 'parent',
        kind: PaymentKind.advance,
        status: PaymentStatus.resolved,
        amount: 100000,
        resolvedAmount: 80000,
        children: [
          payment(
            id: 'c1',
            parentId: 'parent',
            kind: PaymentKind.distribution,
            status: PaymentStatus.confirmed,
            amount: 30000,
          ),
          payment(
            id: 'c2',
            parentId: 'parent',
            kind: PaymentKind.distribution,
            status: PaymentStatus.resolved,
            amount: 20000,
            resolvedAmount: 15000,
          ),
        ],
      );
      expect(parent.effectiveAmount, 80000);
      expect(parent.distributedAmount, 45000);
      expect(parent.remainingToDistribute, 35000);
    });

    test('remainingToDistribute может стать отрицательным (превышение)', () {
      // Бэк допускает превышение аванса (warning, не блокирует) — UI должен
      // визуализировать как negative remaining.
      final parent = payment(
        id: 'parent',
        kind: PaymentKind.advance,
        status: PaymentStatus.confirmed,
        amount: 100000,
        children: [
          payment(
            id: 'c1',
            parentId: 'parent',
            kind: PaymentKind.distribution,
            status: PaymentStatus.confirmed,
            amount: 70000,
          ),
          payment(
            id: 'c2',
            parentId: 'parent',
            kind: PaymentKind.distribution,
            status: PaymentStatus.pending,
            amount: 50000,
          ),
        ],
      );
      expect(parent.remainingToDistribute, -20000);
    });
  });

  group('PaymentDispute parsing', () {
    test('open status по умолчанию', () {
      final d = PaymentDispute.parse({
        'id': 'd-1',
        'paymentId': 'p-1',
        'openedById': 'u-1',
        'reason': 'Сумма не совпадает',
        'createdAt': '2026-04-01T10:00:00Z',
      });
      expect(d.status, 'open');
      expect(d.resolvedAt, isNull);
      expect(d.resolution, isNull);
    });

    test('resolved с resolution', () {
      final d = PaymentDispute.parse({
        'id': 'd-1',
        'paymentId': 'p-1',
        'openedById': 'u-1',
        'reason': 'Сумма не совпадает',
        'status': 'resolved',
        'resolution': 'Сумма скорректирована',
        'resolvedAt': '2026-04-02T10:00:00Z',
        'resolvedBy': 'customer-1',
        'createdAt': '2026-04-01T10:00:00Z',
      });
      expect(d.status, 'resolved');
      expect(d.resolution, isNotNull);
      expect(d.resolvedAt, isNotNull);
    });
  });
}
