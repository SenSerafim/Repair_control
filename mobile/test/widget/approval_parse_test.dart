import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/approvals/domain/approval.dart';
import 'package:repair_control/shared/widgets/status_pill.dart';

void main() {
  group('ApprovalScope', () {
    test('roundtrip всех значений', () {
      for (final s in ApprovalScope.values) {
        expect(ApprovalScope.fromString(s.apiValue), s);
      }
    });
    test('unknown → step', () {
      expect(ApprovalScope.fromString('?'), ApprovalScope.step);
    });
    test('все имеют displayName и icon', () {
      for (final s in ApprovalScope.values) {
        expect(s.displayName, isNotEmpty);
        expect(s.shortHint, isNotEmpty);
      }
    });
  });

  group('ApprovalStatus', () {
    test('roundtrip', () {
      for (final s in ApprovalStatus.values) {
        expect(ApprovalStatus.fromString(s.apiValue), s);
      }
    });
    test('pending — не history', () {
      expect(ApprovalStatus.pending.isHistory, isFalse);
      expect(ApprovalStatus.approved.isHistory, isTrue);
      expect(ApprovalStatus.rejected.isHistory, isTrue);
      expect(ApprovalStatus.cancelled.isHistory, isTrue);
    });
    test('semaphore mapping', () {
      expect(ApprovalStatus.pending.semaphore, Semaphore.blue);
      expect(ApprovalStatus.approved.semaphore, Semaphore.green);
      expect(ApprovalStatus.rejected.semaphore, Semaphore.red);
      expect(ApprovalStatus.cancelled.semaphore, Semaphore.plan);
    });
  });

  group('Approval.parse с payload', () {
    test('plan с списком этапов', () {
      final a = Approval.parse({
        'id': 'a1',
        'scope': 'plan',
        'projectId': 'p1',
        'status': 'pending',
        'requestedById': 'u1',
        'addresseeId': 'u2',
        'attemptNumber': 1,
        'payload': {
          'stages': [
            {'stageId': 's1', 'title': 'Демонтаж'},
            {'stageId': 's2', 'title': 'Электрика'},
          ],
        },
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(a.scope, ApprovalScope.plan);
      expect(a.planStages.length, 2);
      expect(a.planStages.first['title'], 'Демонтаж');
    });

    test('deadline_change с newEnd', () {
      final a = Approval.parse({
        'id': 'a1',
        'scope': 'deadline_change',
        'projectId': 'p1',
        'stageId': 'st1',
        'status': 'pending',
        'requestedById': 'u1',
        'addresseeId': 'u2',
        'attemptNumber': 1,
        'payload': {'newEnd': '2026-05-15T00:00:00Z'},
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(a.newEnd?.year, 2026);
      expect(a.newEnd?.month, 5);
      expect(a.newEnd?.day, 15);
    });

    test('extra_work с price + description', () {
      final a = Approval.parse({
        'id': 'a1',
        'scope': 'extra_work',
        'projectId': 'p1',
        'stageId': 'st1',
        'stepId': 'step1',
        'status': 'pending',
        'requestedById': 'u1',
        'addresseeId': 'u2',
        'attemptNumber': 2,
        'payload': {
          'price': 50_000_00,
          'description': 'Доп.демонтаж стены',
        },
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(a.extraPrice, 50_000_00);
      expect(a.extraDescription, 'Доп.демонтаж стены');
      expect(a.attemptNumber, 2);
    });

    test('с attempts history', () {
      final a = Approval.parse({
        'id': 'a1',
        'scope': 'step',
        'projectId': 'p1',
        'status': 'rejected',
        'requestedById': 'u1',
        'addresseeId': 'u2',
        'attemptNumber': 1,
        'decidedAt': '2026-04-22T11:00:00Z',
        'decidedById': 'u2',
        'decisionComment': 'Не готово',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T11:00:00Z',
        'attempts': [
          {
            'id': 'att1',
            'approvalId': 'a1',
            'attemptNumber': 1,
            'action': 'created',
            'actorId': 'u1',
            'createdAt': '2026-04-22T10:00:00Z',
          },
          {
            'id': 'att2',
            'approvalId': 'a1',
            'attemptNumber': 1,
            'action': 'rejected',
            'actorId': 'u2',
            'comment': 'Не готово',
            'createdAt': '2026-04-22T11:00:00Z',
          },
        ],
      });
      expect(a.status, ApprovalStatus.rejected);
      expect(a.attempts.length, 2);
      expect(a.attempts.last.action, 'rejected');
      expect(a.decisionComment, 'Не готово');
    });
  });
}
