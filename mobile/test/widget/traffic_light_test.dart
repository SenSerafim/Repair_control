import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/stages/domain/stage.dart';
import 'package:repair_control/features/stages/domain/traffic_light.dart';

void main() {
  Stage stageOf({
    required StageStatus status,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    DateTime? startedAt,
  }) =>
      Stage.parse({
        'id': 'x',
        'projectId': 'p',
        'title': 't',
        'orderIndex': 0,
        'status': status.name,
        'pauseDurationMs': 0,
        'workBudget': 0,
        'materialsBudget': 0,
        'foremanIds': <String>[],
        'progressCache': 0,
        'planApproved': false,
        if (plannedStart != null)
          'plannedStart': plannedStart.toIso8601String(),
        if (plannedEnd != null) 'plannedEnd': plannedEnd.toIso8601String(),
        if (startedAt != null) 'startedAt': startedAt.toIso8601String(),
        'createdAt': '2026-04-01T00:00:00Z',
        'updatedAt': '2026-04-01T00:00:00Z',
      });

  final now = DateTime.utc(2026, 4, 22);
  final past = DateTime.utc(2026, 3, 1);
  final future = DateTime.utc(2026, 5, 30);

  group('computeTrafficLight — 5 веток ТЗ §2.4', () {
    test('done → green (даже если дедлайн прошёл)', () {
      final s = stageOf(
        status: StageStatus.done,
        plannedEnd: past,
      );
      expect(computeTrafficLight(s, now: now), TrafficLight.green);
    });

    test('active без просрочки → green', () {
      final s = stageOf(
        status: StageStatus.active,
        plannedStart: past,
        plannedEnd: future,
      );
      expect(computeTrafficLight(s, now: now), TrafficLight.green);
    });

    test('paused → yellow', () {
      final s = stageOf(
        status: StageStatus.paused,
        plannedStart: past,
        plannedEnd: future,
      );
      expect(computeTrafficLight(s, now: now), TrafficLight.yellow);
    });

    test('review → blue', () {
      final s = stageOf(
        status: StageStatus.review,
        plannedStart: past,
        plannedEnd: future,
      );
      expect(computeTrafficLight(s, now: now), TrafficLight.blue);
    });

    test('rejected → red', () {
      final s = stageOf(status: StageStatus.rejected);
      expect(computeTrafficLight(s, now: now), TrafficLight.red);
    });

    test('overdue (active + plannedEnd прошёл) → red', () {
      final s = stageOf(
        status: StageStatus.active,
        plannedStart: past,
        plannedEnd: past,
      );
      expect(computeTrafficLight(s, now: now), TrafficLight.red);
    });

    test('lateStart (pending + plannedStart прошёл) → red', () {
      final s = stageOf(
        status: StageStatus.pending,
        plannedStart: past,
        plannedEnd: future,
      );
      expect(computeTrafficLight(s, now: now), TrafficLight.red);
    });

    test('pending в плановых сроках → grey', () {
      final s = stageOf(
        status: StageStatus.pending,
        plannedStart: future,
        plannedEnd: future.add(const Duration(days: 14)),
      );
      expect(computeTrafficLight(s, now: now), TrafficLight.grey);
    });

    test('paused переопределяет overdue (yellow, не red)', () {
      // Etap на паузе И срок прошёл — yellow важнее, чтобы пользователь
      // видел что причина известна и срок будет сдвинут после resume.
      final s = stageOf(
        status: StageStatus.paused,
        plannedStart: past,
        plannedEnd: past,
      );
      expect(computeTrafficLight(s, now: now), TrafficLight.yellow);
    });
  });

  group('computeProjectTrafficLight — агрегатор', () {
    test('пустой список → grey', () {
      expect(computeProjectTrafficLight(const []), TrafficLight.grey);
    });

    test('все этапы done → green', () {
      final stages = [
        stageOf(status: StageStatus.done),
        stageOf(status: StageStatus.done),
      ];
      expect(computeProjectTrafficLight(stages, now: now), TrafficLight.green);
    });

    test('хоть один просрочен → red (доминирует)', () {
      final stages = [
        stageOf(status: StageStatus.active, plannedEnd: future),
        stageOf(status: StageStatus.paused),
        stageOf(status: StageStatus.active, plannedEnd: past),
      ];
      expect(computeProjectTrafficLight(stages, now: now), TrafficLight.red);
    });

    test('пауза без просрочек → yellow', () {
      final stages = [
        stageOf(status: StageStatus.active, plannedEnd: future),
        stageOf(status: StageStatus.paused),
      ];
      expect(computeProjectTrafficLight(stages, now: now), TrafficLight.yellow);
    });

    test('review без просрочек/паузы → blue', () {
      final stages = [
        stageOf(status: StageStatus.review),
        stageOf(status: StageStatus.done),
      ];
      expect(computeProjectTrafficLight(stages, now: now), TrafficLight.blue);
    });

    test('активный без просрочек → green', () {
      final stages = [
        stageOf(status: StageStatus.active, plannedEnd: future),
        stageOf(status: StageStatus.pending, plannedStart: future),
      ];
      expect(computeProjectTrafficLight(stages, now: now), TrafficLight.green);
    });
  });
}
