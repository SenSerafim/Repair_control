// NEWFIX gaps Task 1.2: проверяет поведение кнопки «Написать в чат»
// на профиле сотрудника.
//
// Сценарии:
//  1) `objects` пуст → показывается SnackBar «Нет общих проектов…»,
//     `createPersonal` не вызывается.
//  2) В `objects` есть как минимум один общий проект → вызывается
//     `ChatsRepository.createPersonal(projectId: <первый>, withUserId: <id>)`,
//     и происходит навигация на `/chats/<chatId>`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_control/features/chat/data/chats_repository.dart';
import 'package:repair_control/features/chat/domain/chat.dart';
import 'package:repair_control/features/user_profile/data/user_profile_repository.dart';
import 'package:repair_control/features/user_profile/domain/user_profile_aggregate.dart';
import 'package:repair_control/features/user_profile/presentation/user_profile_screen.dart';

class _FakeChatsRepository extends Fake implements ChatsRepository {
  int createPersonalCalls = 0;
  String? lastProjectId;
  String? lastWithUserId;
  Chat? toReturn;

  @override
  Future<Chat> createPersonal({
    required String projectId,
    required String withUserId,
  }) async {
    createPersonalCalls++;
    lastProjectId = projectId;
    lastWithUserId = withUserId;
    return toReturn!;
  }
}

UserProfileAggregate _buildAggregate({
  required List<UserProfileObject> objects,
}) {
  return UserProfileAggregate(
    user: const UserProfileHeader(
      id: 'u1',
      firstName: 'Иван',
      lastName: 'Петров',
      phone: '+79991112233',
      activeRole: 'master',
    ),
    objects: objects,
    monthStats: const UserProfileMonthStats(stepsDoneThisMonth: 0),
    tools: const [],
    reclamations: const UserProfileReclamations(completed: 0, total: 0),
    payouts: const UserProfilePayouts(
      visible: false,
      monthTotal: 0,
      byProject: [],
    ),
  );
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/users/u1',
    routes: [
      GoRoute(
        path: '/users/:id',
        builder: (_, state) =>
            UserProfileScreen(userId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/chats/:chatId',
        builder: (_, state) =>
            Scaffold(body: Text('chat:${state.pathParameters['chatId']}')),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'если общих проектов нет — показывается SnackBar и createPersonal не вызывается',
    (tester) async {
      final fakeRepo = _FakeChatsRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileAggregateProvider(
              'u1',
            ).overrideWith((ref) async => _buildAggregate(objects: const [])),
            chatsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp.router(routerConfig: _buildRouter()),
        ),
      );
      await tester.pumpAndSettle();

      final button = find.byKey(const ValueKey('user_profile_chat_button'));
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pump(); // даём SnackBar появиться

      expect(
        find.text('Нет общих проектов с этим сотрудником'),
        findsOneWidget,
      );
      expect(fakeRepo.createPersonalCalls, 0);
    },
  );

  testWidgets(
    'при наличии общего проекта вызывается createPersonal и навигация на /chats/<id>',
    (tester) async {
      final fakeRepo = _FakeChatsRepository()
        ..toReturn = Chat(
          id: 'chat-1',
          type: ChatType.personal,
          projectId: 'proj-1',
          visibleToCustomer: true,
          createdById: 'tester',
          createdAt: DateTime.utc(2026, 6, 8),
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileAggregateProvider('u1').overrideWith(
              (ref) async => _buildAggregate(
                objects: const [
                  UserProfileObject(
                    projectId: 'proj-1',
                    title: 'Объект А',
                    role: 'master',
                    stages: [],
                  ),
                  UserProfileObject(
                    projectId: 'proj-2',
                    title: 'Объект Б',
                    role: 'master',
                    stages: [],
                  ),
                ],
              ),
            ),
            chatsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp.router(routerConfig: _buildRouter()),
        ),
      );
      await tester.pumpAndSettle();

      final button = find.byKey(const ValueKey('user_profile_chat_button'));
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(fakeRepo.createPersonalCalls, 1);
      expect(fakeRepo.lastProjectId, 'proj-1');
      expect(fakeRepo.lastWithUserId, 'u1');
      expect(find.text('chat:chat-1'), findsOneWidget);
    },
  );
}
