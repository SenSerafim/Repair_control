import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/materials/domain/material_request.dart';
import 'package:repair_control/features/selfpurchase/domain/self_purchase.dart';
import 'package:repair_control/features/tools/domain/tool.dart';

void main() {
  group('MaterialRequestStatus', () {
    test('roundtrip всех 8 значений', () {
      for (final s in MaterialRequestStatus.values) {
        expect(MaterialRequestStatus.fromString(s.apiValue), s);
      }
    });

    test('isTerminal правильный', () {
      expect(MaterialRequestStatus.resolved.isTerminal, isTrue);
      expect(MaterialRequestStatus.cancelled.isTerminal, isTrue);
      expect(MaterialRequestStatus.delivered.isTerminal, isTrue);
      expect(MaterialRequestStatus.open.isTerminal, isFalse);
      expect(MaterialRequestStatus.disputed.isTerminal, isFalse);
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
    test('с items и расчётом bought', () {
      final r = MaterialRequest.parse({
        'id': 'm1',
        'projectId': 'p1',
        'createdById': 'u1',
        'recipient': 'foreman',
        'title': 'Электрика 1',
        'status': 'partially_bought',
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
            'isBought': true,
            'createdAt': '2026-04-22T10:00:00Z',
            'updatedAt': '2026-04-22T10:00:00Z',
          },
          {
            'id': 'i2',
            'requestId': 'm1',
            'name': 'Розетки',
            'qty': 20,
            'unit': 'шт',
            'isBought': false,
            'createdAt': '2026-04-22T10:00:00Z',
            'updatedAt': '2026-04-22T10:00:00Z',
          },
        ],
      });
      expect(r.items.length, 2);
      expect(r.boughtItemsCount, 1);
      expect(r.totalBoughtPrice, 5000_00);
      expect(r.allItemsBought, isFalse);
    });

    test('decimal qty', () {
      final r = MaterialRequest.parse({
        'id': 'm1',
        'projectId': 'p1',
        'createdById': 'u1',
        'recipient': 'customer',
        'title': 'T',
        'status': 'draft',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
        'items': [
          {
            'id': 'i1',
            'requestId': 'm1',
            'name': 'Штукатурка',
            'qty': '12.5',
            'unit': 'кг',
            'isBought': false,
            'createdAt': '2026-04-22T10:00:00Z',
            'updatedAt': '2026-04-22T10:00:00Z',
          },
        ],
      });
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

  group('ToolIssuanceStatus', () {
    test('roundtrip', () {
      for (final s in ToolIssuanceStatus.values) {
        expect(ToolIssuanceStatus.fromString(s.apiValue), s);
      }
    });
  });

  group('ToolItem extension', () {
    test('availableQty и isAllIssued', () {
      final t = ToolItem.parse({
        'id': 't1',
        'ownerId': 'u1',
        'name': 'Перфоратор',
        'totalQty': 3,
        'issuedQty': 2,
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(t.availableQty, 1);
      expect(t.isAllIssued, isFalse);
    });

    test('весь выдан', () {
      final t = ToolItem.parse({
        'id': 't1',
        'ownerId': 'u1',
        'name': 'Перфоратор',
        'totalQty': 1,
        'issuedQty': 1,
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(t.availableQty, 0);
      expect(t.isAllIssued, isTrue);
    });
  });

  group('ToolIssuance.parse', () {
    test('с вложенным tool', () {
      final i = ToolIssuance.parse({
        'id': 'i1',
        'toolItemId': 't1',
        'projectId': 'p1',
        'toUserId': 'u2',
        'issuedById': 'u1',
        'qty': 2,
        'status': 'issued',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
        'tool': {
          'id': 't1',
          'ownerId': 'u1',
          'name': 'Уровень',
          'totalQty': 5,
          'issuedQty': 2,
          'createdAt': '2026-04-22T10:00:00Z',
          'updatedAt': '2026-04-22T10:00:00Z',
        },
      });
      expect(i.status, ToolIssuanceStatus.issued);
      expect(i.tool?.name, 'Уровень');
    });
  });
}
