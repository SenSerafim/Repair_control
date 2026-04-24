import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/steps/domain/step.dart' as domain;
import 'package:repair_control/shared/widgets/status_pill.dart';

void main() {
  group('StepType.fromString', () {
    test('extra и regular', () {
      expect(domain.StepType.fromString('extra'), domain.StepType.extra);
      expect(domain.StepType.fromString('regular'), domain.StepType.regular);
      expect(domain.StepType.fromString(null), domain.StepType.regular);
      expect(domain.StepType.fromString('?'), domain.StepType.regular);
    });
  });

  group('StepStatus.fromString', () {
    test('все варианты', () {
      expect(
        domain.StepStatus.fromString('pending'),
        domain.StepStatus.pending,
      );
      expect(
        domain.StepStatus.fromString('in_progress'),
        domain.StepStatus.inProgress,
      );
      expect(
        domain.StepStatus.fromString('done'),
        domain.StepStatus.done,
      );
      expect(
        domain.StepStatus.fromString('pending_approval'),
        domain.StepStatus.pendingApproval,
      );
      expect(
        domain.StepStatus.fromString('rejected'),
        domain.StepStatus.rejected,
      );
    });

    test('apiValue roundtrip', () {
      for (final s in domain.StepStatus.values) {
        expect(domain.StepStatus.fromString(s.apiValue), s);
      }
    });

    test('semaphore mapping', () {
      expect(
        domain.StepStatus.pending.semaphore,
        Semaphore.plan,
      );
      expect(
        domain.StepStatus.inProgress.semaphore,
        Semaphore.green,
      );
      expect(
        domain.StepStatus.done.semaphore,
        Semaphore.green,
      );
      expect(
        domain.StepStatus.pendingApproval.semaphore,
        Semaphore.blue,
      );
      expect(
        domain.StepStatus.rejected.semaphore,
        Semaphore.red,
      );
    });
  });

  group('Step.parse', () {
    test('regular step с substeps inline', () {
      final s = domain.Step.parse({
        'id': 's1',
        'stageId': 'st1',
        'title': 'Штукатурка',
        'orderIndex': 0,
        'type': 'regular',
        'status': 'in_progress',
        'authorId': 'u1',
        'assigneeIds': ['u2', 'u3'],
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
        'substeps': [
          {'isDone': true},
          {'isDone': false},
        ],
        'photos': [
          {'id': 'p1'},
        ],
      });
      expect(s.type, domain.StepType.regular);
      expect(s.status, domain.StepStatus.inProgress);
      expect(s.assigneeIds, ['u2', 'u3']);
      expect(s.substepsCount, 2);
      expect(s.substepsDone, 1);
      expect(s.photosCount, 1);
      expect(s.isExtra, isFalse);
      expect(s.isDone, isFalse);
    });

    test('extra step с ценой', () {
      final s = domain.Step.parse({
        'id': 's1',
        'stageId': 'st1',
        'title': 'Доп. перегородка',
        'orderIndex': 5,
        'type': 'extra',
        'status': 'pending_approval',
        'price': 25_000_00,
        'authorId': 'u1',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(s.isExtra, isTrue);
      expect(s.price, 25_000_00);
      expect(s.status, domain.StepStatus.pendingApproval);
    });
  });
}
