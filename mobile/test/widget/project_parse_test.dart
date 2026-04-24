import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/projects/application/projects_list_controller.dart';
import 'package:repair_control/features/projects/domain/project.dart';
import 'package:repair_control/shared/widgets/status_pill.dart';

void main() {
  group('Project.parse', () {
    test('минимальный активный проект', () {
      final p = Project.parse({
        'id': 'p1',
        'ownerId': 'u1',
        'title': 'Квартира на Ленина',
        'status': 'active',
        'workBudget': 1_000_000_00,
        'materialsBudget': 500_000_00,
        'progressCache': 42,
        'semaphoreCache': 'green',
        'planApproved': false,
        'requiresPlanApproval': false,
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(p.id, 'p1');
      expect(p.status, ProjectStatus.active);
      expect(p.semaphore, Semaphore.green);
      expect(p.workBudget, 1_000_000_00);
      expect(p.totalBudget, 1_500_000_00);
      expect(p.isArchived, isFalse);
    });

    test('semaphoreCache=plan → Semaphore.plan', () {
      final p = Project.parse({
        'id': 'p1',
        'ownerId': 'u1',
        'title': 'T',
        'status': 'active',
        'workBudget': 0,
        'materialsBudget': 0,
        'progressCache': 0,
        'semaphoreCache': 'plan',
        'planApproved': false,
        'requiresPlanApproval': false,
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(p.semaphore, Semaphore.plan);
    });

    test('архивный проект', () {
      final p = Project.parse({
        'id': 'p2',
        'ownerId': 'u1',
        'title': 'X',
        'status': 'archived',
        'workBudget': 0,
        'materialsBudget': 0,
        'progressCache': 100,
        'semaphoreCache': 'green',
        'planApproved': true,
        'requiresPlanApproval': true,
        'archivedAt': '2026-04-23T10:00:00Z',
        'createdAt': '2026-04-01T10:00:00Z',
        'updatedAt': '2026-04-23T10:00:00Z',
      });
      expect(p.isArchived, isTrue);
      expect(p.archivedAt, isNotNull);
    });

    test('semaphoreLabel для всех веток', () {
      for (final (raw, expectedLabel) in [
        ('green', 'По графику'),
        ('yellow', 'Отставание'),
        ('red', 'Просрочен'),
        ('blue', 'Согласования'),
        ('plan', 'В плане'),
      ]) {
        final p = _minimal(semaphore: raw);
        expect(p.semaphoreLabel, expectedLabel);
      }
    });
  });

  group('ProjectsFilter.matches', () {
    test('all матчит всё', () {
      expect(ProjectsFilter.all.matches(_minimal(semaphore: 'red')), isTrue);
    });

    test('ok матчит только green', () {
      expect(ProjectsFilter.ok.matches(_minimal(semaphore: 'green')), isTrue);
      expect(
        ProjectsFilter.ok.matches(_minimal(semaphore: 'yellow')),
        isFalse,
      );
    });

    test('late_ матчит только red', () {
      expect(ProjectsFilter.late_.matches(_minimal(semaphore: 'red')), isTrue);
      expect(
        ProjectsFilter.late_.matches(_minimal(semaphore: 'green')),
        isFalse,
      );
    });

    test('approval матчит только blue', () {
      expect(
        ProjectsFilter.approval.matches(_minimal(semaphore: 'blue')),
        isTrue,
      );
    });
  });
}

Project _minimal({required String semaphore}) => Project.parse({
      'id': 'x',
      'ownerId': 'u',
      'title': 'x',
      'status': 'active',
      'workBudget': 0,
      'materialsBudget': 0,
      'progressCache': 0,
      'semaphoreCache': semaphore,
      'planApproved': false,
      'requiresPlanApproval': false,
      'createdAt': '2026-04-22T10:00:00Z',
      'updatedAt': '2026-04-22T10:00:00Z',
    });
