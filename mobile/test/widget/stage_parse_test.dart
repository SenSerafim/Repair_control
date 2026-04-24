import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/stages/domain/stage.dart';
import 'package:repair_control/shared/widgets/status_pill.dart';

void main() {
  group('StageStatus.fromString', () {
    test('все известные', () {
      expect(StageStatus.fromString('pending'), StageStatus.pending);
      expect(StageStatus.fromString('active'), StageStatus.active);
      expect(StageStatus.fromString('paused'), StageStatus.paused);
      expect(StageStatus.fromString('review'), StageStatus.review);
      expect(StageStatus.fromString('done'), StageStatus.done);
      expect(StageStatus.fromString('rejected'), StageStatus.rejected);
    });

    test('unknown → pending', () {
      expect(StageStatus.fromString('wtf'), StageStatus.pending);
      expect(StageStatus.fromString(null), StageStatus.pending);
    });

    test('semaphore mapping', () {
      expect(StageStatus.pending.semaphore, Semaphore.plan);
      expect(StageStatus.active.semaphore, Semaphore.green);
      expect(StageStatus.paused.semaphore, Semaphore.yellow);
      expect(StageStatus.review.semaphore, Semaphore.blue);
      expect(StageStatus.done.semaphore, Semaphore.green);
      expect(StageStatus.rejected.semaphore, Semaphore.red);
    });
  });

  group('Stage.parse', () {
    test('минимальный активный', () {
      final s = Stage.parse({
        'id': 's1',
        'projectId': 'p1',
        'title': 'Демонтаж',
        'orderIndex': 0,
        'status': 'active',
        'pauseDurationMs': 0,
        'workBudget': 100_000_00,
        'materialsBudget': 0,
        'foremanIds': ['u1'],
        'progressCache': 35,
        'planApproved': true,
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(s.id, 's1');
      expect(s.status, StageStatus.active);
      expect(s.foremanIds, ['u1']);
      expect(s.progressCache, 35);
    });
  });

  group('StageX.isLateStart', () {
    test('pending + plannedStart в прошлом + startedAt=null → true', () {
      final s = _minimal(
        status: 'pending',
        plannedStart: '2026-04-01T00:00:00Z',
      );
      final now = DateTime.utc(2026, 4, 22);
      expect(s.isLateStart(now), isTrue);
    });

    test('active → false (уже стартовал)', () {
      final s = _minimal(
        status: 'active',
        plannedStart: '2026-04-01T00:00:00Z',
        startedAt: '2026-04-10T00:00:00Z',
      );
      final now = DateTime.utc(2026, 4, 22);
      expect(s.isLateStart(now), isFalse);
    });

    test('pending + plannedStart в будущем → false', () {
      final s = _minimal(
        status: 'pending',
        plannedStart: '2026-05-01T00:00:00Z',
      );
      final now = DateTime.utc(2026, 4, 22);
      expect(s.isLateStart(now), isFalse);
    });
  });
}

Stage _minimal({
  required String status,
  String? plannedStart,
  String? startedAt,
}) {
  return Stage.parse({
    'id': 'x',
    'projectId': 'p',
    'title': 't',
    'orderIndex': 0,
    'status': status,
    'pauseDurationMs': 0,
    'workBudget': 0,
    'materialsBudget': 0,
    'foremanIds': <String>[],
    'progressCache': 0,
    'planApproved': false,
    if (plannedStart != null) 'plannedStart': plannedStart,
    if (startedAt != null) 'startedAt': startedAt,
    'createdAt': '2026-04-01T00:00:00Z',
    'updatedAt': '2026-04-01T00:00:00Z',
  });
}
