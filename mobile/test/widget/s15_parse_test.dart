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

    test(
      'isTerminal: только acceptedFull/rejected — терминальные (E1a FSM)',
      () {
        // ТЗ NEWFIX §5.7: заявка считается закрытой только после полной приёмки
        // или отказа. approved/delivered/acceptedPartial — промежуточные.
        expect(MaterialRequestStatus.acceptedFull.isTerminal, isTrue);
        expect(MaterialRequestStatus.rejected.isTerminal, isTrue);
        expect(MaterialRequestStatus.approved.isTerminal, isFalse);
        expect(MaterialRequestStatus.delivered.isTerminal, isFalse);
        expect(MaterialRequestStatus.acceptedPartial.isTerminal, isFalse);
        expect(MaterialRequestStatus.pendingApproval.isTerminal, isFalse);
      },
    );

    test('legacy / E1a: парсинг всех статусов из API', () {
      // Активные статусы FSM E1a (ТЗ NEWFIX §5.7).
      expect(
        MaterialRequestStatus.fromString('pending_approval'),
        MaterialRequestStatus.pendingApproval,
      );
      expect(
        MaterialRequestStatus.fromString('open'),
        MaterialRequestStatus.approved,
      );
      expect(
        MaterialRequestStatus.fromString('delivered'),
        MaterialRequestStatus.delivered,
      );
      expect(
        MaterialRequestStatus.fromString('accepted_partial'),
        MaterialRequestStatus.acceptedPartial,
      );
      expect(
        MaterialRequestStatus.fromString('accepted_full'),
        MaterialRequestStatus.acceptedFull,
      );
      expect(
        MaterialRequestStatus.fromString('cancelled'),
        MaterialRequestStatus.rejected,
      );
      // Legacy-значения БД (bought / resolved) — пока маппим в approved.
      expect(
        MaterialRequestStatus.fromString('bought'),
        MaterialRequestStatus.approved,
      );
      expect(
        MaterialRequestStatus.fromString('resolved'),
        MaterialRequestStatus.approved,
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

  group('E1a — Заявки 2.0 (NEWFIX §5.7)', () {
    test('MaterialItem.parse: actualQty + dueDate + photo', () {
      final item = MaterialItem.parse({
        'id': 'mi1',
        'requestId': 'mr1',
        'name': 'Цемент',
        'qty': 40,
        'actualQty': 20,
        'dueDate': '2026-06-15T00:00:00Z',
        'photo': {
          'id': 'mip1',
          'fileKey': 'materials/items/photos/2026-05-27/abc.jpg',
          'thumbKey': null,
          'mimeType': 'image/jpeg',
          'sizeBytes': 524288,
          'uploadedBy': 'u1',
          'exifCleared': true,
          'createdAt': '2026-05-27T10:00:00Z',
        },
        'isBought': false,
        'createdAt': '2026-05-27T10:00:00Z',
        'updatedAt': '2026-05-27T10:00:00Z',
      });
      expect(item.actualQty, 20);
      expect(item.dueDate, DateTime.utc(2026, 6, 15));
      expect(item.photo, isNotNull);
      expect(item.photo!.fileKey, contains('abc.jpg'));
      expect(item.photo!.mimeType, 'image/jpeg');
      expect(item.photo!.exifCleared, isTrue);
    });

    test('MaterialItem.parse без photo и без dueDate — opt-out поля', () {
      final item = MaterialItem.parse({
        'id': 'mi2',
        'requestId': 'mr2',
        'name': 'Песок',
        'qty': 10,
        'isBought': false,
        'createdAt': '2026-05-27T10:00:00Z',
        'updatedAt': '2026-05-27T10:00:00Z',
      });
      expect(item.actualQty, isNull);
      expect(item.dueDate, isNull);
      expect(item.photo, isNull);
    });

    test('isOverdue: approved + просроченный dueDate → true', () {
      final now = DateTime.utc(2026, 7, 1);
      final r = MaterialRequest(
        id: 'r1',
        projectId: 'p1',
        createdById: 'u1',
        recipient: MaterialRecipient.foreman,
        title: 'X',
        status: MaterialRequestStatus.approved,
        createdAt: now,
        updatedAt: now,
        items: [
          MaterialItem(
            id: 'i1',
            requestId: 'r1',
            name: 'X',
            qty: 1,
            dueDate: DateTime.utc(2026, 6, 15), // в прошлом относительно now
            isBought: false,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      expect(r.isOverdue(now), isTrue);
    });

    test(
      'isOverdue: delivered/acceptedPartial — НЕ просрочена даже с прошедшим dueDate',
      () {
        // ТЗ §5.5: «Просрочена» = ждёт доставки И срок прошёл.
        // Если уже доставили — статус уже delivered/accepted_*, флаг неактуален.
        final now = DateTime.utc(2026, 7, 1);
        final past = DateTime.utc(2026, 6, 15);
        for (final s in [
          MaterialRequestStatus.delivered,
          MaterialRequestStatus.acceptedPartial,
          MaterialRequestStatus.acceptedFull,
          MaterialRequestStatus.pendingApproval,
        ]) {
          final r = MaterialRequest(
            id: 'r',
            projectId: 'p',
            createdById: 'u',
            recipient: MaterialRecipient.foreman,
            title: 'X',
            status: s,
            createdAt: now,
            updatedAt: now,
            items: [
              MaterialItem(
                id: 'i',
                requestId: 'r',
                name: 'X',
                qty: 1,
                dueDate: past,
                isBought: false,
                createdAt: now,
                updatedAt: now,
              ),
            ],
          );
          expect(r.isOverdue(now), isFalse, reason: 'status=$s');
        }
      },
    );

    test('canMarkDelivered / canAccept: матрица переходов FSM', () {
      MaterialRequest mk(MaterialRequestStatus s) => MaterialRequest(
        id: 'r',
        projectId: 'p',
        createdById: 'u',
        recipient: MaterialRecipient.foreman,
        title: 'X',
        status: s,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      // canMarkDelivered: approved / acceptedPartial
      expect(mk(MaterialRequestStatus.approved).canMarkDelivered, isTrue);
      expect(
        mk(MaterialRequestStatus.acceptedPartial).canMarkDelivered,
        isTrue,
      );
      expect(
        mk(MaterialRequestStatus.pendingApproval).canMarkDelivered,
        isFalse,
      );
      expect(mk(MaterialRequestStatus.delivered).canMarkDelivered, isFalse);
      expect(mk(MaterialRequestStatus.acceptedFull).canMarkDelivered, isFalse);
      // canAccept: только delivered
      expect(mk(MaterialRequestStatus.delivered).canAccept, isTrue);
      expect(mk(MaterialRequestStatus.approved).canAccept, isFalse);
      expect(mk(MaterialRequestStatus.acceptedPartial).canAccept, isFalse);
    });

    test('displayName и semaphore для всех 6 статусов уникальны', () {
      final names = <String>{};
      for (final s in MaterialRequestStatus.values) {
        names.add(s.displayName);
      }
      expect(names.length, MaterialRequestStatus.values.length);
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
