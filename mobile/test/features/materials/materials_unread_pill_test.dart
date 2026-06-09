// Task 8.2 (TZ-2 §5.4): «колокольчик» на списке заявок проекта.
//
// Тестируем рендер пилюли по разнице createdAt > lastSeenAt и эффект
// «отметить всё прочитанным» — после тапа `markAllSeen` вызван, state
// обновлён, пилюля пропадает.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/core/access/access_guard.dart';
import 'package:repair_control/core/access/system_role.dart';
import 'package:repair_control/features/materials/application/materials_controller.dart';
import 'package:repair_control/features/materials/domain/material_request.dart';
import 'package:repair_control/features/materials/presentation/materials_list_screen.dart';
import 'package:repair_control/features/stages/application/stages_controller.dart';
import 'package:repair_control/features/stages/domain/stage.dart';

MaterialRequest _req({
  required String id,
  required String title,
  required DateTime createdAt,
}) {
  return MaterialRequest(
    id: id,
    projectId: 'p1',
    createdById: 'u1',
    recipient: MaterialRecipient.foreman,
    title: title,
    status: MaterialRequestStatus.approved,
    createdAt: createdAt,
    updatedAt: createdAt,
    items: const [],
  );
}

Widget _harness({required List<Override> overrides}) {
  return ProviderScope(
    overrides: [
      // Активная роль = заказчик: чтобы canProvider(materialsManage) = true,
      // но это не критично для пилюли — она показывается всем.
      activeRoleProvider.overrideWithValue(SystemRole.customer),
      stagesControllerProvider.overrideWith(_StubStages.new),
      ...overrides,
    ],
    child: const MaterialApp(
      home: MaterialsListScreen(projectId: 'p1'),
    ),
  );
}

void main() {
  testWidgets(
    'показывает пилюлю «5 новых заявок» когда все 5 заявок новее lastSeen',
    (tester) async {
      final t0 = DateTime(2026, 6, 1);
      final items = [
        for (var i = 0; i < 5; i++)
          _req(
            id: 'r$i',
            title: 'A$i',
            createdAt: t0.add(Duration(days: i + 1)),
          ),
      ];

      await tester.pumpWidget(
        _harness(
          overrides: [
            materialsControllerProvider.overrideWith(
              () => _StubMaterials(items),
            ),
            materialsLastSeenProvider.overrideWith(
              () => _StubLastSeen(t0),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 5 — ветка mod10>=5 → «5 новых заявок».
      expect(find.text('5 новых заявок'), findsOneWidget);
      expect(
        find.byIcon(Icons.notifications_active_rounded),
        findsOneWidget,
      );
    },
  );

  testWidgets('3 новые заявки рендерятся в ветке 2-4 (плюрализация RU)', (
    tester,
  ) async {
    final t0 = DateTime(2026, 6, 1);
    final items = [
      _req(id: 'r1', title: 'A', createdAt: t0.add(const Duration(days: 1))),
      _req(id: 'r2', title: 'B', createdAt: t0.add(const Duration(days: 2))),
      _req(id: 'r3', title: 'C', createdAt: t0.add(const Duration(days: 3))),
    ];

    await tester.pumpWidget(
      _harness(
        overrides: [
          materialsControllerProvider.overrideWith(
            () => _StubMaterials(items),
          ),
          materialsLastSeenProvider.overrideWith(() => _StubLastSeen(t0)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 новые заявки'), findsOneWidget);
  });

  testWidgets(
    'не показывает пилюлю когда новых заявок нет (lastSeen свежее всех '
    'createdAt)',
    (tester) async {
      final t0 = DateTime(2026, 6, 1);
      final items = [
        _req(
          id: 'r1',
          title: 'старая',
          createdAt: t0.subtract(const Duration(days: 1)),
        ),
      ];

      await tester.pumpWidget(
        _harness(
          overrides: [
            materialsControllerProvider.overrideWith(
              () => _StubMaterials(items),
            ),
            materialsLastSeenProvider.overrideWith(
              () => _StubLastSeen(t0),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 новых заявок'), findsNothing);
      expect(find.text('1 новая заявка'), findsNothing);
      expect(
        find.byIcon(Icons.notifications_active_rounded),
        findsNothing,
      );
    },
  );

  testWidgets(
    'не показывает пилюлю при первом заходе (lastSeen == null → 0 unread)',
    (tester) async {
      final items = [
        _req(id: 'r1', title: 'A', createdAt: DateTime(2026, 6, 5)),
      ];

      await tester.pumpWidget(
        _harness(
          overrides: [
            materialsControllerProvider.overrideWith(
              () => _StubMaterials(items),
            ),
            materialsLastSeenProvider.overrideWith(
              () => _StubLastSeen(null),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 новых заявок'), findsNothing);
      expect(find.text('1 новая заявка'), findsNothing);
      expect(
        find.byIcon(Icons.notifications_active_rounded),
        findsNothing,
      );
    },
  );

  testWidgets(
    'тап по пилюле вызывает markAllSeen → пилюля исчезает',
    (tester) async {
      final t0 = DateTime(2026, 6, 1);
      final items = [
        _req(id: 'r1', title: 'A', createdAt: t0.add(const Duration(days: 1))),
        _req(id: 'r2', title: 'B', createdAt: t0.add(const Duration(days: 2))),
      ];
      final lastSeenStub = _StubLastSeen(t0);

      await tester.pumpWidget(
        _harness(
          overrides: [
            materialsControllerProvider.overrideWith(
              () => _StubMaterials(items),
            ),
            materialsLastSeenProvider.overrideWith(() => lastSeenStub),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Бейдж виден до клика.
      expect(find.text('2 новые заявки'), findsOneWidget);

      await tester.tap(find.text('2 новые заявки'));
      await tester.pumpAndSettle();

      // markAllSeen вызван и сохранил timestamp в стаб.
      expect(lastSeenStub.markAllSeenCallCount, 1);
      expect(lastSeenStub.writtenValue, isNotNull);
      // Бейдж пропал.
      expect(find.text('2 новые заявки'), findsNothing);
      expect(
        find.byIcon(Icons.notifications_active_rounded),
        findsNothing,
      );
    },
  );
}

class _StubMaterials extends MaterialsController {
  _StubMaterials(this._items);
  final List<MaterialRequest> _items;
  @override
  Future<List<MaterialRequest>> build(String projectId) async => _items;
}

class _StubStages extends StagesController {
  @override
  Future<List<Stage>> build(String projectId) async => const <Stage>[];
}

/// Имитирует SecureStorage-backed контроллер: в build возвращает заданный
/// timestamp, в markAllSeen — сохраняет «now» и обновляет state. Считаем
/// количество вызовов markAllSeen и значение, которое было бы записано в
/// storage.
class _StubLastSeen extends MaterialsLastSeenController {
  _StubLastSeen(this._initial);
  final DateTime? _initial;
  int markAllSeenCallCount = 0;
  DateTime? writtenValue;

  @override
  Future<DateTime?> build(String projectId) async => _initial;

  @override
  Future<void> markAllSeen() async {
    markAllSeenCallCount++;
    final now = DateTime.now().toUtc();
    writtenValue = now;
    state = AsyncData(now);
  }
}
