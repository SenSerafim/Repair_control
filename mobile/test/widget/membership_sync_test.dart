// Покрывает реал-тайм синхронизацию состава команды:
// при WS-событиях `project:membership_changed` / `participant:added` /
// `participant:removed` / `notification:new(kind=membership_*)` и reconnect
// провайдер `membershipSyncProvider` обязан инвалидировать
// `activeProjectsProvider` и `myChatsProvider` — иначе у пользователей
// продолжают висеть устаревшие списки (главная жалоба).
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/core/access/system_role.dart';
import 'package:repair_control/core/realtime/socket_service.dart';
import 'package:repair_control/features/auth/application/auth_controller.dart';
import 'package:repair_control/features/chat/application/chats_controller.dart';
import 'package:repair_control/features/chat/data/chats_repository.dart';
import 'package:repair_control/features/projects/application/membership_sync.dart';
import 'package:repair_control/features/projects/application/projects_list_controller.dart';
import 'package:repair_control/features/projects/data/projects_repository.dart';
import 'package:repair_control/features/projects/domain/project.dart';

/// Fake `SocketService`: возвращает контролируемые потоки и позволяет
/// «руками» эмитить события. `extends Fake implements SocketService` —
/// неиспользуемые методы кидают, и это нам как раз и надо: чтобы тест
/// падал, если sync неожиданно дёрнет лишний API socket'а.
class _FakeSocketService extends Fake implements SocketService {
  final _events = StreamController<(String, dynamic)>.broadcast();
  final _conn = StreamController<bool>.broadcast();

  @override
  Stream<bool> get connectedStream => _conn.stream;

  @override
  Stream<(String, dynamic)> get eventsStream => _events.stream;

  @override
  Stream<dynamic> on(String event) =>
      _events.stream.where((t) => t.$1 == event).map((t) => t.$2);

  void injectEvent(String event, dynamic payload) {
    _events.add((event, payload));
  }

  void injectConnected({required bool value}) {
    _conn.add(value);
  }
}

/// Счётчик вызовов `list()` — детектор инвалидации (после `ref.invalidate`
/// очередное чтение провайдера снова дёрнет `list()` → инкремент).
class _CountingProjectsRepository extends Fake implements ProjectsRepository {
  int listCalls = 0;

  @override
  Future<List<Project>> list({ProjectStatus? status, String? role}) async {
    listCalls++;
    return const <Project>[];
  }
}

class _CountingChatsRepository extends Fake implements ChatsRepository {
  int listMineCalls = 0;

  @override
  Future<List<MyChatItem>> listMine() async {
    listMineCalls++;
    return const <MyChatItem>[];
  }
}

class _TestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
        status: AuthStatus.authenticated,
        userId: 'tester',
        activeRole: SystemRole.customer,
      );
}

void main() {
  late _FakeSocketService socket;
  late _CountingProjectsRepository projectsRepo;
  late _CountingChatsRepository chatsRepo;
  late ProviderContainer container;

  setUp(() {
    socket = _FakeSocketService();
    projectsRepo = _CountingProjectsRepository();
    chatsRepo = _CountingChatsRepository();
    container = ProviderContainer(
      overrides: [
        socketServiceProvider.overrideWithValue(socket),
        projectsRepositoryProvider.overrideWithValue(projectsRepo),
        chatsRepositoryProvider.overrideWithValue(chatsRepo),
        // authControllerProvider читается activeRoleProvider'ом, который
        // используется в build() activeProjectsProvider — без override
        // выпадает RangeError на чтении secure_storage в unit-окружении.
        authControllerProvider.overrideWith(_TestAuthController.new),
      ],
    );
  });

  tearDown(() => container.dispose());

  /// Прогревает оба ключевых провайдера, чтобы они дали ровно по одному
  /// `list()` / `listMine()` вызову до начала «настоящей» проверки.
  Future<void> warmUpProviders() async {
    await container.read(activeProjectsProvider.future);
    await container.read(myChatsProvider.future);
    expect(projectsRepo.listCalls, 1, reason: 'initial active projects build');
    expect(chatsRepo.listMineCalls, 1, reason: 'initial my chats build');
  }

  test(
    'project:membership_changed инвалидирует activeProjects и myChats',
    () async {
      container.read(membershipSyncProvider);
      await warmUpProviders();

      socket.injectEvent('project:membership_changed', {
        'projectId': 'p1',
        'userId': 'u-new',
        'role': 'master',
        'action': 'added',
      });
      // 2 микротаска: 1 — broadcast stream доставляет событие;
      //               2 — riverpod применяет invalidate.
      await Future<void>.delayed(Duration.zero);

      await container.read(activeProjectsProvider.future);
      await container.read(myChatsProvider.future);
      // `greaterThan(1)`, а не `==2`: AsyncNotifier'у при invalidate может
      // понадобиться 2 build-цикла (loading→data), важно зафиксировать сам
      // факт пересборки после WS-события.
      expect(
        projectsRepo.listCalls,
        greaterThan(1),
        reason: 'activeProjectsProvider должен пересобраться после WS-события',
      );
      expect(
        chatsRepo.listMineCalls,
        greaterThan(1),
        reason: 'myChatsProvider тоже инвалидируется (новые чаты в проекте)',
      );
    },
  );

  test(
    'notification:new(kind=membership_added) — backup-канал, тоже инвалидирует',
    () async {
      container.read(membershipSyncProvider);
      await warmUpProviders();

      socket.injectEvent('notification:new', {
        'kind': 'membership_added',
        'title': 'Вас добавили в проект',
        'body': '',
      });
      await Future<void>.delayed(Duration.zero);

      await container.read(activeProjectsProvider.future);
      expect(projectsRepo.listCalls, greaterThan(1));
    },
  );

  test(
    'notification:new с НЕ-membership kind не вызывает лишних инвалидаций',
    () async {
      container.read(membershipSyncProvider);
      await warmUpProviders();

      socket.injectEvent('notification:new', {
        'kind': 'approval_requested',
        'title': '',
        'body': '',
      });
      await Future<void>.delayed(Duration.zero);

      await container.read(activeProjectsProvider.future);
      expect(projectsRepo.listCalls, 1, reason: 'approval-уведомления не трогают список проектов');
    },
  );

  test(
    'reconnect (connectedStream=true) → backfill активных проектов',
    () async {
      container.read(membershipSyncProvider);
      await warmUpProviders();

      socket.injectConnected(value: true);
      await Future<void>.delayed(Duration.zero);

      await container.read(activeProjectsProvider.future);
      expect(
        projectsRepo.listCalls,
        greaterThan(1),
        reason:
            'события за время disconnect потеряны → при reconnect обязательно '
            'перезагружаем основные списки',
      );
    },
  );

  test(
    'participant:added инвалидирует myChats (но не activeProjects)',
    () async {
      container.read(membershipSyncProvider);
      await warmUpProviders();

      socket.injectEvent('participant:added', {
        'chatId': 'c1',
        'userId': 'u-new',
      });
      await Future<void>.delayed(Duration.zero);

      await container.read(myChatsProvider.future);
      await container.read(activeProjectsProvider.future);
      expect(
        chatsRepo.listMineCalls,
        greaterThan(1),
        reason: 'добавление в чат → обновляем список чатов',
      );
      expect(projectsRepo.listCalls, 1, reason: 'chat-уровень не трогает список проектов');
    },
  );

  test('SocketEvents.projectMembershipChanged соответствует backend-каналу', () {
    // Защита от опечаток в имени канала: оно должно совпадать ровно с тем,
    // что эмитит `ChatsGateway.onProjectMembershipChanged`.
    expect(SocketEvents.projectMembershipChanged, 'project:membership_changed');
  });
}
