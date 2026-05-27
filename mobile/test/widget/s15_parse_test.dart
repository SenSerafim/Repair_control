import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/materials/domain/material_request.dart';
import 'package:repair_control/features/selfpurchase/domain/self_purchase.dart';
import 'package:repair_control/features/tools/domain/tool.dart';

void main() {
  group('MaterialRequestStatus', () {
    test('roundtrip всех значений', () {
      for (final s in MaterialRequestStatus.values) {
        expect(MaterialRequestStatus.fromString(s.apiValue), s);
      }
    });

    test('isTerminal: approved/rejected — терминальные, pendingApproval — нет', () {
      expect(MaterialRequestStatus.approved.isTerminal, isTrue);
      expect(MaterialRequestStatus.rejected.isTerminal, isTrue);
      expect(MaterialRequestStatus.pendingApproval.isTerminal, isFalse);
    });

    test('legacy bought/delivered/resolved/cancelled → approved/rejected', () {
      // BE-наследие (S15) — пока БД хранит старые значения, парсим в новые.
      expect(
        MaterialRequestStatus.fromString('bought'),
        MaterialRequestStatus.approved,
      );
      expect(
        MaterialRequestStatus.fromString('delivered'),
        MaterialRequestStatus.approved,
      );
      expect(
        MaterialRequestStatus.fromString('resolved'),
        MaterialRequestStatus.approved,
      );
      expect(
        MaterialRequestStatus.fromString('cancelled'),
        MaterialRequestStatus.rejected,
      );
    });
  });

  group('MaterialRecipient', () {
    test('roundtrip', () {
      for (final r in MaterialRecipient.values) {
        expect(MaterialRecipient.fromString(r.apiValue), r);
      }
    });
  });

  group('MaterialRequest.parse', () {
    test('approved заявка с items + totalEstimatedPrice', () {
      final r = MaterialRequest.parse({
        'id': 'm1',
        'projectId': 'p1',
        'createdById': 'u1',
        'recipient': 'foreman',
        'title': 'Электрика 1',
        'status': 'open',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
        'items': [
          {
            'id': 'i1',
            'requestId': 'm1',
            'name': 'Кабель ВВГ 3×2.5',
            'qty': 100,
            'unit': 'м',
            'pricePerUnit': 50_00,
            'totalPrice': 5000_00,
            'createdAt': '2026-04-22T10:00:00Z',
            'updatedAt': '2026-04-22T10:00:00Z',
          },
          {
            'id': 'i2',
            'requestId': 'm1',
            'name': 'Розетки',
            'qty': 20,
            'unit': 'шт',
            'pricePerUnit': 100_00,
            'totalPrice': 2000_00,
            'createdAt': '2026-04-22T10:00:00Z',
            'updatedAt': '2026-04-22T10:00:00Z',
          },
        ],
      });
      expect(r.status, MaterialRequestStatus.approved);
      expect(r.items.length, 2);
      expect(r.totalEstimatedPrice, 5000_00 + 2000_00);
    });

    test('decimal qty + pending_approval', () {
      final r = MaterialRequest.parse({
        'id': 'm1',
        'projectId': 'p1',
        'createdById': 'u1',
        'recipient': 'customer',
        'title': 'T',
        'status': 'pending_approval',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
        'items': [
          {
            'id': 'i1',
            'requestId': 'm1',
            'name': 'Штукатурка',
            'qty': '12.5',
            'unit': 'кг',
            'createdAt': '2026-04-22T10:00:00Z',
            'updatedAt': '2026-04-22T10:00:00Z',
          },
        ],
      });
      expect(r.status, MaterialRequestStatus.pendingApproval);
      expect(r.items.first.qty, 12.5);
    });
  });

  group('SelfPurchaseStatus / By', () {
    test('roundtrip', () {
      for (final s in SelfPurchaseStatus.values) {
        expect(SelfPurchaseStatus.fromString(s.apiValue), s);
      }
      for (final b in SelfPurchaseBy.values) {
        expect(SelfPurchaseBy.fromString(b.apiValue), b);
      }
    });
  });

  group('SelfPurchase.parse', () {
    test('с photoKeys', () {
      final sp = SelfPurchase.parse({
        'id': 'sp1',
        'projectId': 'p1',
        'byUserId': 'u1',
        'byRole': 'master',
        'addresseeId': 'u2',
        'amount': 5000_00,
        'comment': 'Купил краску',
        'photoKeys': ['k1', 'k2'],
        'status': 'pending',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(sp.amount, 5000_00);
      expect(sp.photoKeys, ['k1', 'k2']);
      expect(sp.byRole, SelfPurchaseBy.master);
    });
  });

  group('ToolItem (self-custody модель, 2026-05-12)', () {
    test('isInProject / isHeldBy / isOwnedBy', () {
      final t = ToolItem.parse({
        'id': 't1',
        'ownerId': 'u1',
        'currentHolderId': 'u2',
        'name': 'Перфоратор',
        'projectId': 'p1',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(t.isInProject, isTrue);
      expect(t.isOwnedBy('u1'), isTrue);
      expect(t.isOwnedBy('u2'), isFalse);
      expect(t.isHeldBy('u2'), isTrue);
      expect(t.isHeldBy('u1'), isFalse);
    });

    test('parse с enriched owner/holder', () {
      final t = ToolItem.parse({
        'id': 't1',
        'ownerId': 'u1',
        'currentHolderId': 'u2',
        'name': 'Уровень',
        'projectId': 'p1',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
        '_owner': {'id': 'u1', 'firstName': 'Иван', 'lastName': 'Петров'},
        '_holder': {'id': 'u2', 'firstName': 'Пётр', 'lastName': 'Сидоров'},
      });
      expect(t.owner?.displayName, 'Иван Петров');
      expect(t.holder?.displayName, 'Пётр Сидоров');
    });

    test('currentHolderId fallback на ownerId если поле отсутствует', () {
      final t = ToolItem.parse({
        'id': 't1',
        'ownerId': 'u1',
        'name': 'Перфоратор',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(t.currentHolderId, 'u1');
      expect(t.isInProject, isFalse);
    });
  });

  group('ToolCustodyEvent.parse', () {
    test('initial event имеет previousHolderId == null', () {
      final e = ToolCustodyEvent.parse({
        'id': 'ev1',
        'toolItemId': 't1',
        'projectId': 'p1',
        'holderId': 'u1',
        'previousHolderId': null,
        'createdAt': '2026-04-22T10:00:00Z',
      });
      expect(e.isInitial, isTrue);
      expect(e.previousHolderId, isNull);
    });

    test('claim event с previousHolderId и note', () {
      final e = ToolCustodyEvent.parse({
        'id': 'ev2',
        'toolItemId': 't1',
        'projectId': 'p1',
        'holderId': 'u2',
        'previousHolderId': 'u1',
        'note': 'на 3 этаж',
        'createdAt': '2026-04-22T11:00:00Z',
      });
      expect(e.isInitial, isFalse);
      expect(e.holderId, 'u2');
      expect(e.previousHolderId, 'u1');
      expect(e.note, 'на 3 этаж');
    });
  });
}
