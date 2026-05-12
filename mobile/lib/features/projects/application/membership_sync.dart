import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/socket_service.dart';
import '../../chat/application/chats_controller.dart';
import '../../team/application/team_controller.dart';
import 'project_controller.dart';
import 'projects_list_controller.dart';

/// Глобальный синхронизатор membership-событий. Подписывается на WebSocket-
/// канал, прилетающий от `ChatsGateway` после изменений состава команды
/// проекта (add / remove / leave / joinByCode), и инвалидирует все relevant
/// Riverpod-провайдеры на мобайле — у всех затронутых юзеров одновременно.
///
/// Зачем отдельный провайдер: backend по ТЗ §13.2 шлёт push только адресату
/// (новый/удалённый член), а остальной команде — тихий
/// `project:membership_changed`. Этот канал инвалидирует UI без шума push'ей.
///
/// События, на которые подписываемся:
///  * `project:membership_changed` — основной сигнал.
///  * `notification:new` (kind=membership_added/removed) — резервный канал,
///    срабатывает, если основной WS-broadcast был потерян (reconnect-окно).
///  * `participant:added`/`participant:removed` — chat-уровень: личные/групповые
///    чаты, требующие обновления списка чатов.
///  * Reconnect-stream — после реконнекта инвалидируем глобально, потому что
///    события за время disconnect навсегда потеряны.
///
/// Регистрируется в `app.dart::_initServices` через `ref.read(membershipSyncProvider)`
/// сразу после `socketAutoconnectProvider`.
final membershipSyncProvider = Provider<void>((ref) {
  final socket = ref.read(socketServiceProvider);
  final subs = <StreamSubscription<dynamic>>[];

  void invalidateGlobal() {
    // Глобальная инвалидация без projectId: основные списки, которые показывают
    // «во что я добавлен / откуда меня убрали». Используется как fallback,
    // когда из payload не понять projectId.
    ref
      ..invalidate(activeProjectsProvider)
      ..invalidate(archivedProjectsProvider)
      ..invalidate(myChatsProvider);
  }

  void invalidateForProject(String? projectId) {
    invalidateGlobal();
    if (projectId == null || projectId.isEmpty) return;
    // Family-провайдеры — инвалидируем точечно по projectId, чтобы не дёргать
    // другие открытые проекты.
    ref
      ..invalidate(teamControllerProvider(projectId))
      ..invalidate(projectChatsProvider(projectId))
      ..invalidate(projectControllerProvider(projectId));
  }

  subs
    ..add(
      socket.on(SocketEvents.projectMembershipChanged).listen((payload) {
        final map = payload is Map ? payload : null;
        final projectId = map?['projectId'] as String?;
        invalidateForProject(projectId);
      }),
    )
    // Backup-канал на случай если основной project:membership_changed был
    // пропущен (например, во время reconnect-окна или ошибки на бэкенде).
    // notification:new для membership_* приходит только адресату — этого
    // достаточно, чтобы у нового/удалённого юзера обновился список проектов.
    ..add(
      socket.on(SocketEvents.notificationNew).listen((payload) {
        final kind = (payload is Map ? payload['kind'] : null) as String?;
        if (kind == 'membership_added' || kind == 'membership_removed') {
          invalidateGlobal();
        }
      }),
    )
    ..add(
      socket.on(SocketEvents.participantAdded).listen((_) {
        ref.invalidate(myChatsProvider);
      }),
    )
    ..add(
      socket.on(SocketEvents.participantRemoved).listen((_) {
        ref.invalidate(myChatsProvider);
      }),
    )
    // Backfill при reconnect: WS-события за время disconnect навсегда потеряны
    // (на бекенде нет outbox-доставки). Инвалидируем после disconnect→connect
    // цикла; первый `connected=true` после подписки пропускаем, т.к. list-
    // провайдеры только что отработали build() — дубль был бы пустой запрос
    // (наблюдалось на старте: GET /projects?role=master летел 2–3 раза).
    ..add(
      () {
        var sawDisconnect = false;
        return socket.connectedStream.listen((connected) {
          if (!connected) {
            sawDisconnect = true;
            return;
          }
          if (!sawDisconnect) return;
          sawDisconnect = false;
          invalidateGlobal();
        });
      }(),
    );

  ref.onDispose(() {
    for (final s in subs) {
      s.cancel();
    }
  });
});
