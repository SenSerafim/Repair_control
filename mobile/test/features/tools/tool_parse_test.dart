import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/tools/domain/tool.dart';

void main() {
  group('ToolCondition', () {
    test('roundtrip всех значений', () {
      for (final c in ToolCondition.values) {
        expect(ToolCondition.fromString(c.apiValue), c);
      }
    });

    test('null/unknown → null', () {
      expect(ToolCondition.fromString(null), isNull);
      expect(ToolCondition.fromString('unknown'), isNull);
    });

    test('все имеют displayName', () {
      for (final c in ToolCondition.values) {
        expect(c.displayName, isNotEmpty);
      }
    });
  });

  group('ToolItem.parse — NEWFIX §6.1', () {
    test('parse без purchaseDate/condition — оба null', () {
      final t = ToolItem.parse({
        'id': 't1',
        'ownerId': 'u1',
        'currentHolderId': 'u1',
        'name': 'Перфоратор',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(t.purchaseDate, isNull);
      expect(t.condition, isNull);
    });

    test('parse с purchaseDate и condition=good', () {
      final t = ToolItem.parse({
        'id': 't1',
        'ownerId': 'u1',
        'currentHolderId': 'u1',
        'name': 'Перфоратор',
        'purchaseDate': '2025-06-01T00:00:00Z',
        'condition': 'good',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(t.purchaseDate?.year, 2025);
      expect(t.purchaseDate?.month, 6);
      expect(t.condition, ToolCondition.good);
    });

    test('parse condition=new_tool корректно мапится в ToolCondition.newTool', () {
      final t = ToolItem.parse({
        'id': 't1',
        'ownerId': 'u1',
        'currentHolderId': 'u1',
        'name': 'Перфоратор',
        'condition': 'new_tool',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      expect(t.condition, ToolCondition.newTool);
    });

    test('copyWith сохраняет purchaseDate/condition', () {
      final orig = ToolItem.parse({
        'id': 't1',
        'ownerId': 'u1',
        'currentHolderId': 'u1',
        'name': 'Перфоратор',
        'purchaseDate': '2025-06-01T00:00:00Z',
        'condition': 'worn',
        'createdAt': '2026-04-22T10:00:00Z',
        'updatedAt': '2026-04-22T10:00:00Z',
      });
      final renamed = orig.copyWith(name: 'Перфоратор Bosch');
      expect(renamed.purchaseDate, orig.purchaseDate);
      expect(renamed.condition, ToolCondition.worn);
    });
  });
}
