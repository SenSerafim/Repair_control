// Task 2.1 (TZ-фронт §11): 4-й таб «Заявки» на экране деталей этапа.
//
// Проверяем фильтрацию заявок по stageId и пустое состояние.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/materials/application/materials_controller.dart';
import 'package:repair_control/features/materials/domain/material_request.dart';
import 'package:repair_control/features/materials/presentation/_widgets/material_card.dart';
import 'package:repair_control/features/stages/presentation/_widgets/stage_requests_tab.dart';
import 'package:repair_control/shared/widgets/widgets.dart';

MaterialRequest _req({
  required String id,
  required String title,
  String? stageId,
  MaterialRequestStatus status = MaterialRequestStatus.approved,
}) {
  return MaterialRequest(
    id: id,
    projectId: 'p1',
    stageId: stageId,
    createdById: 'u1',
    recipient: MaterialRecipient.foreman,
    title: title,
    status: status,
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
    items: const [],
  );
}

void main() {
  testWidgets(
    'StageRequestsTab фильтрует заявки по stageId — видны только 2 из 3',
    (tester) async {
      final items = [
        _req(id: 'r1', title: 'Заявка A1', stageId: 's1'),
        _req(id: 'r2', title: 'Заявка A2', stageId: 's1'),
        _req(id: 'r3', title: 'Заявка B1', stageId: 's2'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            materialsControllerProvider.overrideWith(
              () => _StubController(items),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StageRequestsTab(projectId: 'p1', stageId: 's1'),
            ),
          ),
        ),
      );
      // Ждём, пока async завершится, список отрисуется, и анимации (в т.ч.
      // fadeIn в AppEmptyState) докрутятся. Без pumpAndSettle остаются
      // pending Timer'ы и тест падает на _verifyInvariants.
      await tester.pumpAndSettle();

      // На экране ровно 2 карточки MaterialCard.
      expect(find.byType(MaterialCard), findsNWidgets(2));
      // Видны заголовки заявок этапа s1.
      expect(find.text('Заявка A1'), findsOneWidget);
      expect(find.text('Заявка A2'), findsOneWidget);
      // Заявка чужого этапа не показана.
      expect(find.text('Заявка B1'), findsNothing);
      // Пустого состояния нет.
      expect(find.byType(AppEmptyState), findsNothing);
    },
  );

  testWidgets(
    'StageRequestsTab показывает AppEmptyState при пустом отфильтрованном '
    'списке',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            materialsControllerProvider.overrideWith(
              () => _StubController(const []),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StageRequestsTab(projectId: 'p1', stageId: 's1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Нет заявок на этом этапе'), findsOneWidget);
      expect(find.byType(MaterialCard), findsNothing);
    },
  );

  testWidgets(
    'StageRequestsTab игнорирует общие заявки проекта (stageId=null)',
    (tester) async {
      final items = [
        _req(id: 'r1', title: 'Заявка A1', stageId: 's1'),
        _req(id: 'r2', title: 'Общая заявка'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            materialsControllerProvider.overrideWith(
              () => _StubController(items),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StageRequestsTab(projectId: 'p1', stageId: 's1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MaterialCard), findsOneWidget);
      expect(find.text('Заявка A1'), findsOneWidget);
      expect(find.text('Общая заявка'), findsNothing);
    },
  );
}

/// Стабовый контроллер, возвращающий заранее заданный список заявок.
/// Используем `overrideWith(() => …)` (а не `overrideWith((ref) async => …)`)
/// — это контракт `AsyncNotifierProvider.family` в Riverpod 2.
class _StubController extends MaterialsController {
  _StubController(this._items);

  final List<MaterialRequest> _items;

  @override
  Future<List<MaterialRequest>> build(String projectId) async => _items;
}
