import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/finance/domain/budget.dart';
import 'package:repair_control/features/finance/domain/payment.dart';
import 'package:repair_control/shared/widgets/status_pill.dart';

void main() {
  group('PaymentKind / PaymentStatus', () {
    test('roundtrip всех значений', () {
      for (final k in PaymentKind.values) {
        expect(PaymentKind.fromString(k.apiValue), k);
      }
      for (final s in PaymentStatus.values) {
        expect(PaymentStatus.fromString(s.apiValue), s);
      }
    });

    test('unknown → advance / pending', () {
      expect(PaymentKind.fromString(null), PaymentKind.advance);
      expect(PaymentKind.fromString('?'), PaymentKind.advance);
      expect(PaymentStatus.fromString(null), PaymentStatus.pending);
    });

    test('semaphore mapping', () {
      expect(PaymentStatus.pending.semaphore, Semaphore.blue);
      expect(PaymentStatus.confirmed.semaphore, Semaphore.green);
      expect(PaymentStatus.disputed.semaphore, Semaphore.red);
      expect(PaymentStatus.resolved.semaphore, Semaphore.plan);
      expect(PaymentStatus.cancelled.semaphore, Semaphore.plan);
    });
  });

  group('Payment.parse', () {
    test('advance без детей', () {
      final p = Payment.parse({
        'id': 'pay1',
        'projectId': 'pr1',
        'kind': 'advance',
        'fromUserId': 'u1',
        'toUserId': 'u2',
        'amount': 500_000_00,
        'status': 'pending',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(p.kind, PaymentKind.advance);
      expect(p.status, PaymentStatus.pending);
      expect(p.amount, 500_000_00);
      expect(p.children, isEmpty);
      expect(p.distributedAmount, 0);
      expect(p.remainingToDistribute, 500_000_00);
      expect(p.effectiveAmount, 500_000_00);
    });

    test('advance с child-distributions', () {
      final p = Payment.parse({
        'id': 'pay1',
        'projectId': 'pr1',
        'kind': 'advance',
        'fromUserId': 'u1',
        'toUserId': 'u2',
        'amount': 500_000_00,
        'status': 'confirmed',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
        'children': [
          {
            'id': 'c1',
            'projectId': 'pr1',
            'parentPaymentId': 'pay1',
            'kind': 'distribution',
            'fromUserId': 'u2',
            'toUserId': 'u3',
            'amount': 200_000_00,
            'status': 'pending',
            'createdAt': '2026-04-22T11:00:00Z',
            'updatedAt': '2026-04-22T11:00:00Z',
          },
          {
            'id': 'c2',
            'projectId': 'pr1',
            'parentPaymentId': 'pay1',
            'kind': 'distribution',
            'fromUserId': 'u2',
            'toUserId': 'u4',
            'amount': 150_000_00,
            'status': 'confirmed',
            'createdAt': '2026-04-22T11:30:00Z',
            'updatedAt': '2026-04-22T11:30:00Z',
          },
        ],
      });
      expect(p.children.length, 2);
      expect(p.distributedAmount, 350_000_00);
      expect(p.remainingToDistribute, 150_000_00);
    });

    test('resolved с корректировкой', () {
      final p = Payment.parse({
        'id': 'pay1',
        'projectId': 'pr1',
        'kind': 'distribution',
        'fromUserId': 'u1',
        'toUserId': 'u2',
        'amount': 100_000_00,
        'resolvedAmount': 80_000_00,
        'status': 'resolved',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-23T10:00:00Z',
      });
      expect(p.effectiveAmount, 80_000_00);
      expect(p.amount, 100_000_00);
    });
  });

  group('BudgetBucket', () {
    test('progress rendering', () {
      const b = BudgetBucket(planned: 100_00, spent: 25_00, remaining: 75_00);
      expect(b.progress, closeTo(0.25, 0.0001));
      expect(b.overSpent, isFalse);
    });

    test('overSpent → progress clamped к 1.0', () {
      const b =
          BudgetBucket(planned: 100_00, spent: 150_00, remaining: -50_00);
      expect(b.progress, 1.0);
      expect(b.overSpent, isTrue);
    });

    test('planned=0 → progress=0 (нет деления на 0)', () {
      const b = BudgetBucket.empty;
      expect(b.progress, 0.0);
      expect(b.overSpent, isFalse);
    });

    test('пустой empty', () {
      expect(BudgetBucket.empty.planned, 0);
      expect(BudgetBucket.empty.spent, 0);
    });
  });

  group('ProjectBudget.parse', () {
    test('с несколькими этапами', () {
      final pb = ProjectBudget.parse({
        'work': {'planned': 1_000_000_00, 'spent': 250_000_00, 'remaining': 750_000_00},
        'materials': {'planned': 500_000_00, 'spent': 100_000_00, 'remaining': 400_000_00},
        'total': {'planned': 1_500_000_00, 'spent': 350_000_00, 'remaining': 1_150_000_00},
        'stages': [
          {
            'stageId': 's1',
            'title': 'Демонтаж',
            'work': {'planned': 100_000_00, 'spent': 100_000_00, 'remaining': 0},
            'materials': {'planned': 0, 'spent': 0, 'remaining': 0},
            'total': {'planned': 100_000_00, 'spent': 100_000_00, 'remaining': 0},
          },
        ],
      });
      expect(pb.total.planned, 1_500_000_00);
      expect(pb.stages.length, 1);
      expect(pb.stages.first.title, 'Демонтаж');
      expect(pb.stages.first.total.progress, 1.0);
    });
  });
}
