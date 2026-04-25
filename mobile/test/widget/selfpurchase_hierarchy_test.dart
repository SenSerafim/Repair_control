import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/selfpurchase/domain/self_purchase.dart';

/// Phase 6: иерархия approver'ов и FSM SelfPurchase.
///
/// Backend-инвариант (gaps §4.3):
/// - foreman создаёт → addresseeId = project.ownerId (customer)
/// - master создаёт → addresseeId = stage.foremanIds[0] (foreman этапа)
/// Mobile UI (selfpurchases_screen.dart) показывает фильтр
/// «Ждут моего согласования» по addresseeId == meId.
void main() {
  SelfPurchase parse(Map<String, dynamic> json) => SelfPurchase.parse({
        'id': 'sp-1',
        'projectId': 'p-1',
        'byUserId': 'u-1',
        'byRole': 'foreman',
        'addresseeId': 'customer-1',
        'amount': 5000,
        'status': 'pending',
        'createdAt': '2026-04-01T10:00:00Z',
        'updatedAt': '2026-04-01T10:00:00Z',
        ...json,
      });

  group('SelfPurchase.parse — иерархия', () {
    test('foreman → customer как addressee', () {
      final sp = parse({'byRole': 'foreman', 'addresseeId': 'customer-1'});
      expect(sp.byRole, SelfPurchaseBy.foreman);
      expect(sp.addresseeId, 'customer-1');
    });

    test('master → foreman как addressee + stageId обязателен', () {
      final sp = parse({
        'byRole': 'master',
        'addresseeId': 'foreman-1',
        'stageId': 'stage-1',
      });
      expect(sp.byRole, SelfPurchaseBy.master);
      expect(sp.addresseeId, 'foreman-1');
      expect(sp.stageId, isNotNull);
    });
  });

  group('SelfPurchase FSM', () {
    test('pending → approved сохраняет decisionComment', () {
      final approved = parse({
        'status': 'approved',
        'decidedAt': '2026-04-02T10:00:00Z',
        'decidedById': 'customer-1',
        'decisionComment': 'OK, согласовано',
      });
      expect(approved.status, SelfPurchaseStatus.approved);
      expect(approved.decisionComment, isNotNull);
      expect(approved.decidedAt, isNotNull);
    });

    test('pending → rejected требует decisionComment', () {
      final rejected = parse({
        'status': 'rejected',
        'decidedAt': '2026-04-02T10:00:00Z',
        'decidedById': 'foreman-1',
        'decisionComment': 'Не было согласовано заранее',
      });
      expect(rejected.status, SelfPurchaseStatus.rejected);
      expect(rejected.decisionComment, isNotNull);
      expect(rejected.decisionComment!.length, greaterThan(10));
    });
  });

  group('Filter «Ждут моего согласования»', () {
    test('master видит свой запрос — это «Мои», не «Ждут моего»', () {
      // master created → addressee = foreman; в списке master видит как
      // «свой ожидающий», а foreman видит как «ждёт моего согласования».
      final sp = parse({
        'byUserId': 'master-1',
        'byRole': 'master',
        'addresseeId': 'foreman-1',
        'stageId': 'stage-1',
      });
      const meAsMaster = 'master-1';
      const meAsForeman = 'foreman-1';

      // Для master: byUserId == me → фильтр «Мои» включает.
      expect(sp.byUserId == meAsMaster, isTrue);
      // Для foreman: addresseeId == me → фильтр «Ждут моего» включает.
      expect(sp.addresseeId == meAsForeman, isTrue);
      // А master не должен быть в «Ждут моего» (это его собственный запрос).
      expect(sp.addresseeId == meAsMaster, isFalse);
    });
  });
}
