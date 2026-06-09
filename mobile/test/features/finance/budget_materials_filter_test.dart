// NEWFIX Task 1.5 (TZ-встреча-2 §10.2 + TZ-фронт §5):
// Фильтр по этапу в табе «Материалы» бюджета.
//
// Тестируем чистые фильтрующие функции `filterMaterialPurchasesByStage` и
// `filterSelfpurchasesByStage`, вынесенные из приватного `_MaterialsTab`.
// Полный pump-тест экрана требует override 5+ provider'ов (budget, money-flow,
// stages, materials, selfpurchases) + AccessGuard — слишком инвазивно ради
// одной фичи фильтра. Логика «фильтр по stageId» — pure-функция, тестируется
// напрямую и покрывает все интересные ветки (all / конкретный stageId /
// отсутствующий маппинг).
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/finance/domain/money_flow.dart';
import 'package:repair_control/features/finance/presentation/budget_screen.dart';

void main() {
  group('filterMaterialPurchasesByStage', () {
    const m1 = MaterialPurchaseFlow(
      requestId: 'req-A1',
      title: 'Цемент',
      totalSpent: 1500,
      itemCount: 3,
    );
    const m2 = MaterialPurchaseFlow(
      requestId: 'req-B1',
      title: 'Гипсокартон',
      totalSpent: 8000,
      itemCount: 12,
    );
    const m3 = MaterialPurchaseFlow(
      requestId: 'req-orphan',
      title: 'Без этапа',
      totalSpent: 100,
      itemCount: 1,
    );

    test('activeStageId="all" возвращает исходный список без изменений', () {
      final result = filterMaterialPurchasesByStage(
        rows: [m1, m2, m3],
        stageByRequestId: const {
          'req-A1': 'stage-A',
          'req-B1': 'stage-B',
          'req-orphan': null,
        },
        activeStageId: 'all',
      );
      expect(result, hasLength(3));
      expect(
        result.map((r) => r.requestId),
        containsAll(['req-A1', 'req-B1', 'req-orphan']),
      );
    });

    test('activeStageId="stage-A" оставляет только материалы этапа A', () {
      final result = filterMaterialPurchasesByStage(
        rows: [m1, m2, m3],
        stageByRequestId: const {
          'req-A1': 'stage-A',
          'req-B1': 'stage-B',
          'req-orphan': null,
        },
        activeStageId: 'stage-A',
      );
      expect(result, hasLength(1));
      expect(result.single.title, 'Цемент');
    });

    test('activeStageId="stage-B" не показывает материалы этапа A и orphan', () {
      final result = filterMaterialPurchasesByStage(
        rows: [m1, m2, m3],
        stageByRequestId: const {
          'req-A1': 'stage-A',
          'req-B1': 'stage-B',
          'req-orphan': null,
        },
        activeStageId: 'stage-B',
      );
      expect(result, hasLength(1));
      expect(result.single.title, 'Гипсокартон');
    });

    test('пустой маппинг — конкретный фильтр возвращает пустой список', () {
      final result = filterMaterialPurchasesByStage(
        rows: [m1, m2],
        stageByRequestId: const {},
        activeStageId: 'stage-A',
      );
      expect(result, isEmpty);
    });
  });

  group('filterSelfpurchasesByStage', () {
    final sp1 = ApprovedSelfpurchaseFlow(
      id: 'sp-A',
      byUserId: 'u1',
      byUserName: 'Иван',
      amount: 5000,
      comment: 'самозакуп этапа A',
      decidedAt: DateTime(2026, 6, 1),
    );
    final sp2 = ApprovedSelfpurchaseFlow(
      id: 'sp-B',
      byUserId: 'u2',
      byUserName: 'Пётр',
      amount: 7000,
      comment: 'самозакуп этапа B',
      decidedAt: DateTime(2026, 6, 2),
    );

    test('activeStageId="stage-A" оставляет только самозакуп этапа A', () {
      final result = filterSelfpurchasesByStage(
        rows: [sp1, sp2],
        stageBySelfpurchaseId: const {
          'sp-A': 'stage-A',
          'sp-B': 'stage-B',
        },
        activeStageId: 'stage-A',
      );
      expect(result, hasLength(1));
      expect(result.single.byUserName, 'Иван');
    });

    test('activeStageId="all" возвращает все самозакупы', () {
      final result = filterSelfpurchasesByStage(
        rows: [sp1, sp2],
        stageBySelfpurchaseId: const {
          'sp-A': 'stage-A',
          'sp-B': 'stage-B',
        },
        activeStageId: 'all',
      );
      expect(result, hasLength(2));
    });
  });
}
