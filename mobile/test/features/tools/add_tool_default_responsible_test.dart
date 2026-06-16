// Task 6.4 (NEWFIX TЗ-2 §8.3): при добавлении инструмента в проектном
// контексте ответственный сотрудник по умолчанию = бригадир проекта.
//
// Подход: основной механизм — чистая функция [resolveProjectForemanId] из
// `tools/domain/responsible_resolver.dart`. Полный pump
// `_AddToolToProjectSheet` потребовал бы поднять `socketServiceProvider`,
// `dio`, `chatService`, etc. — слишком тяжело. Поэтому покрываем:
//   1. Чистый resolver (3 кейса: brigadir есть → его id; brigadir нет → null;
//      несколько brigadir → первый по порядку).
//   2. Виджет `AddToolScreen(projectId: ...)` с override'ами `teamControllerProvider`:
//      проверяем, что бригадир pre-fill'ится в state и хинт виден.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/projects/domain/membership.dart';
import 'package:repair_control/features/team/application/team_controller.dart';
import 'package:repair_control/features/tools/domain/responsible_resolver.dart';
import 'package:repair_control/features/tools/presentation/add_tool_screen.dart';

Membership _member({
  required String id,
  required String userId,
  required String firstName,
  required MembershipRole role,
}) {
  return Membership(
    id: id,
    projectId: 'p1',
    userId: userId,
    role: role,
    addedAt: DateTime(2026, 6, 8),
    user: ProjectMemberUser(
      id: userId,
      firstName: firstName,
      lastName: 'Test',
      phone: '+700000000$id',
    ),
  );
}

/// Стабовый team-контроллер: возвращает заранее заданный список членов,
/// без сетевых вызовов.
class _StubTeamController extends TeamController {
  _StubTeamController(this._members);

  final List<Membership> _members;

  @override
  Future<TeamState> build(String projectId) async {
    return TeamState(members: _members, invitations: const []);
  }
}

void main() {
  group('Task 6.4 · resolveProjectForemanId (pure)', () {
    test('возвращает userId бригадира, когда тот единственный в команде', () {
      final members = [
        _member(
          id: 'm-cust',
          userId: 'u-cust',
          firstName: 'Cust',
          role: MembershipRole.customer,
        ),
        _member(
          id: 'm-for',
          userId: 'u-foreman',
          firstName: 'Brigadir',
          role: MembershipRole.foreman,
        ),
        _member(
          id: 'm-mast',
          userId: 'u-master',
          firstName: 'Master',
          role: MembershipRole.master,
        ),
      ];
      expect(resolveProjectForemanId(members), 'u-foreman');
    });

    test('возвращает null, когда бригадира в проекте нет', () {
      final members = [
        _member(
          id: 'm-cust',
          userId: 'u-cust',
          firstName: 'Cust',
          role: MembershipRole.customer,
        ),
        _member(
          id: 'm-mast',
          userId: 'u-master',
          firstName: 'Master',
          role: MembershipRole.master,
        ),
      ];
      expect(resolveProjectForemanId(members), isNull);
    });

    test('возвращает null на пустом списке', () {
      expect(resolveProjectForemanId(const <Membership>[]), isNull);
    });

    test(
      'при двух бригадирах берёт первого (порядок задаётся бекендом '
      'по createdAt)',
      () {
        final members = [
          _member(
            id: 'm-for1',
            userId: 'u-foreman-1',
            firstName: 'First',
            role: MembershipRole.foreman,
          ),
          _member(
            id: 'm-for2',
            userId: 'u-foreman-2',
            firstName: 'Second',
            role: MembershipRole.foreman,
          ),
        ];
        expect(resolveProjectForemanId(members), 'u-foreman-1');
      },
    );
  });

  group('Task 6.4 · AddToolScreen (widget smoke)', () {
    testWidgets(
      'projectId=null → нет хинта «По умолчанию — бригадир» '
      '(старый flow «Мои инструменты»)',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AddToolScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // По умолчанию выбран статус «На складе», поле «assigned employee» не
        // рендерится — хинта тоже не должно быть.
        expect(find.text('По умолчанию — бригадир'), findsNothing);
      },
    );

    testWidgets(
      'projectId задан + бригадир в команде → переключение на статус '
      '«у сотрудника» показывает хинт «По умолчанию — бригадир»',
      (tester) async {
        final members = [
          _member(
            id: 'm-for',
            userId: 'u-foreman',
            firstName: 'Brigadir',
            role: MembershipRole.foreman,
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              // overrideWith(() => …) — стандартный контракт
              // AsyncNotifierProvider.family в Riverpod 2 (перекрывает все
              // инстансы семейства; в тесте нам и нужен только один).
              teamControllerProvider.overrideWith(
                () => _StubTeamController(members),
              ),
            ],
            child: const MaterialApp(
              home: AddToolScreen(projectId: 'p1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Переключаем статус с «На складе» на «У сотрудника».
        await tester.tap(find.text('У сотрудника'));
        await tester.pumpAndSettle();

        // Хинт виден (pre-fill бригадиром применён). skipOffstage:false
        // нужен потому что ListView с большим количеством полей форм
        // отрендерил его в lazy-зону, недоступную обычному find.text.
        expect(
          find.text('По умолчанию — бригадир', skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'projectId задан, но бригадира нет → хинт не показан, экран не падает',
      (tester) async {
        // В команде только заказчик и мастер — бригадира нет.
        final members = [
          _member(
            id: 'm-cust',
            userId: 'u-cust',
            firstName: 'Cust',
            role: MembershipRole.customer,
          ),
          _member(
            id: 'm-mast',
            userId: 'u-master',
            firstName: 'Master',
            role: MembershipRole.master,
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              teamControllerProvider.overrideWith(
                () => _StubTeamController(members),
              ),
            ],
            child: const MaterialApp(
              home: AddToolScreen(projectId: 'p1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Хинта нет (pre-fill не сработал — бригадира не нашли).
        expect(find.text('По умолчанию — бригадир'), findsNothing);
        // Экран рендерится без падения (Scaffold + AppBar присутствуют).
        expect(find.text('Добавить инструмент'), findsOneWidget);
      },
    );
  });
}
