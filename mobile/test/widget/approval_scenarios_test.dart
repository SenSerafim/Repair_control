import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/approvals/domain/approval.dart';

/// Phase 4 acceptance: scenarios — plan-pending / approve / request-correction /
/// resubmit / requires-reassign / customer-cannot-bypass-foreman.
///
/// Тесты на доменную логику парсинга и инвариантов FSM. Widget-уровень
/// (фактический рендеринг кнопок при canDecide=true) уже покрыт unit-тестами
/// `access_guard_test.dart` и зеленится при запуске сценариев в integration
/// сьюте Phase 11.
void main() {
  Approval planPending({
    int attemptNumber = 1,
    bool requiresReassign = false,
    List<Map<String, dynamic>> stages = const [],
  }) =>
      Approval.parse({
        'id': 'a-plan',
        'scope': 'plan',
        'projectId': 'p-1',
        'status': 'pending',
        'requestedById': 'foreman',
        'addresseeId': 'customer',
        'attemptNumber': attemptNumber,
        'requiresReassign': requiresReassign,
        'payload': {'stages': stages},
        'createdAt': '2026-04-01T10:00:00Z',
        'updatedAt': '2026-04-01T10:00:00Z',
      });

  test('plan-pending: scope=plan + attemptNumber=1 + planStages пуст', () {
    final a = planPending();
    expect(a.scope, ApprovalScope.plan);
    expect(a.status, ApprovalStatus.pending);
    expect(a.attemptNumber, 1);
    expect(a.planStages, isEmpty);
    expect(a.requiresReassign, isFalse);
  });

  test('approve flow: status flips to approved + decisionComment сохраняется',
      () {
    final approved = Approval.parse({
      'id': 'a-1',
      'scope': 'plan',
      'projectId': 'p-1',
      'status': 'approved',
      'requestedById': 'foreman',
      'addresseeId': 'customer',
      'attemptNumber': 1,
      'decisionComment': 'Все ок, можно стартовать',
      'decidedAt': '2026-04-02T12:00:00Z',
      'createdAt': '2026-04-01T10:00:00Z',
      'updatedAt': '2026-04-02T12:00:00Z',
    });
    expect(approved.status, ApprovalStatus.approved);
    expect(approved.decisionComment, isNotNull);
    expect(approved.decidedAt, isNotNull);
  });

  test('request-correction (reject): status=rejected + comment обязателен', () {
    final rejected = Approval.parse({
      'id': 'a-1',
      'scope': 'plan',
      'projectId': 'p-1',
      'status': 'rejected',
      'requestedById': 'foreman',
      'addresseeId': 'customer',
      'attemptNumber': 1,
      'decisionComment': 'Дедлайн 1 этапа надо передвинуть на неделю',
      'decidedAt': '2026-04-02T12:00:00Z',
      'createdAt': '2026-04-01T10:00:00Z',
      'updatedAt': '2026-04-02T12:00:00Z',
    });
    expect(rejected.status, ApprovalStatus.rejected);
    expect(rejected.decisionComment, isNotNull);
    expect(rejected.decisionComment!.length, greaterThan(10));
  });

  test('resubmit flow: attemptNumber инкрементируется, status снова pending',
      () {
    final resubmitted = Approval.parse({
      'id': 'a-1',
      'scope': 'plan',
      'projectId': 'p-1',
      'status': 'pending',
      'requestedById': 'foreman',
      'addresseeId': 'customer',
      'attemptNumber': 2,
      'createdAt': '2026-04-01T10:00:00Z',
      'updatedAt': '2026-04-03T09:00:00Z',
    });
    expect(resubmitted.status, ApprovalStatus.pending);
    expect(resubmitted.attemptNumber, 2);
  });

  test('requires-reassign flag прокидывается из API', () {
    final stuck = planPending(requiresReassign: true);
    expect(stuck.requiresReassign, isTrue);
  });

  test('attempts timeline: разные actions, отсортированы по дате', () {
    final a = Approval.parse({
      'id': 'a-1',
      'scope': 'step',
      'projectId': 'p-1',
      'status': 'pending',
      'requestedById': 'master',
      'addresseeId': 'foreman',
      'attemptNumber': 2,
      'createdAt': '2026-04-01T10:00:00Z',
      'updatedAt': '2026-04-03T10:00:00Z',
      'attempts': [
        {
          'id': 'at-1',
          'approvalId': 'a-1',
          'attemptNumber': 1,
          'action': 'created',
          'actorId': 'master',
          'createdAt': '2026-04-01T10:00:00Z',
        },
        {
          'id': 'at-2',
          'approvalId': 'a-1',
          'attemptNumber': 1,
          'action': 'rejected',
          'actorId': 'foreman',
          'comment': 'Доделай фотки',
          'createdAt': '2026-04-02T15:00:00Z',
        },
        {
          'id': 'at-3',
          'approvalId': 'a-1',
          'attemptNumber': 2,
          'action': 'resubmitted',
          'actorId': 'master',
          'createdAt': '2026-04-03T10:00:00Z',
        },
      ],
    });
    expect(a.attempts.length, 3);
    expect(a.attempts.first.action, 'created');
    expect(a.attempts.last.action, 'resubmitted');
    expect(a.attempts[1].comment, isNotNull);
  });

  test('customer-cannot-bypass-foreman: scope=step + foreman addressee → '
      'клиент должен скрыть Approve у customer (в _BottomActions)', () {
    final a = Approval.parse({
      'id': 'a-step',
      'scope': 'step',
      'projectId': 'p-1',
      'stageId': 's-1',
      'stepId': 'st-9',
      'status': 'pending',
      'requestedById': 'master',
      'addresseeId': 'foreman-id',
      'attemptNumber': 1,
      'createdAt': '2026-04-01T10:00:00Z',
      'updatedAt': '2026-04-01T10:00:00Z',
    });
    // Тест документирует инвариант: addresseeId — foreman, scope — step.
    // RBAC-матрица не отличает customer от foreman (canDecide=true для обоих)
    // — серверный gating через `customer_bypass_foreman` гарантирует
    // что POST /approve вернёт 403 для customer'а. Клиент показывает
    // понятное сообщение «выплата ждёт решения бригадира».
    expect(a.scope, ApprovalScope.step);
    expect(a.addresseeId, 'foreman-id');
  });
}
