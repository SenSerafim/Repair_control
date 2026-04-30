import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../features/auth/application/auth_controller.dart';
import '../config/app_env.dart';
import '../config/app_providers.dart';
import '../storage/secure_storage.dart';

/// События из /chats namespace (backend chats.gateway.ts):
/// message:new / message:edited / message:deleted / message:read
/// presence:typing / participant:added / participant:removed
/// chat:visibility_toggled
/// export:ready / export:failed
/// notification:new
class SocketEvents {
  const SocketEvents._();

  static const messageNew = 'message:new';
  static const messageEdited = 'message:edited';
  static const messageDeleted = 'message:deleted';
  static const messageRead = 'message:read';
  static const presenceTyping = 'presence:typing';
  static const participantAdded = 'participant:added';
  static const participantRemoved = 'participant:removed';
  static const chatVisibilityToggled = 'chat:visibility_toggled';
  static const exportReady = 'export:ready';
  static const exportFailed = 'export:failed';
  static const notificationNew = 'notification:new';
}

/// Обёртка над socket_io_client с авто-подключением через JWT и
/// экспоненциальным backoff. Используется ChatsController для real-time
/// обновлений и ExportSheet — для фоновых задач.
class SocketService {
  SocketService({
    required AppEnv env,
    required SecureStorage storage,
    required Logger logger,
  })  : _env = env,
        _storage = storage,
        _logger = logger;

  final AppEnv _env;
  final SecureStorage _storage;
  final Logger _logger;

  io.Socket? _socket;
  bool _connecting = false;
  // Признак намеренного disconnect() — гасит автоматический reconnect при
  // серверном `io server disconnect` (auth fail), чтобы logout не вызывал
  // бесконечный цикл переподключений.
  bool _intentionallyClosed = false;
  // Backoff для server-initiated disconnect: socket.io сам не reconnect-ит,
  // если бэкенд закрыл соединение, поэтому делаем это вручную с экспоненциальной
  // задержкой 1s → 30s.
  int _serverDisconnectAttempts = 0;
  Timer? _reconnectTimer;
  final _connectedController = StreamController<bool>.broadcast();
  final _eventsController =
      StreamController<(String event, dynamic payload)>.broadcast();

  /// Чаты, на которые мы подписаны в текущей сессии. При reconnect socket.io
  /// автоматически переподключится, но НЕ восстановит rooms:join — события
  /// чата приходят к серверу, но клиент не в комнате → не получит. Этот set
  /// используется в onConnect handler, чтобы заново отправить rooms:join.
  final Set<String> _joinedChats = <String>{};

  Stream<bool> get connectedStream => _connectedController.stream;
  Stream<(String, dynamic)> get eventsStream => _eventsController.stream;

  /// Фильтрованный поток по имени события.
  Stream<dynamic> on(String event) =>
      eventsStream.where((t) => t.$1 == event).map((t) => t.$2);

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    // State-guard: пропускаем повторный connect, если уже соединены или
    // в процессе. socket.io сам восстанавливает соединение при transport
    // error через `setReconnectionAttempts(-1)` — нам не надо его дёргать.
    if (_socket != null || _connecting) return;
    _connecting = true;
    _intentionallyClosed = false;
    _reconnectTimer?.cancel();
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) {
      _connecting = false;
      return;
    }

    final url = '${_env.wsUrl}/chats';
    // Сначала создаём socket, потом цепляем callbacks отдельным statement —
    // в cascade обращаться к самой переменной нельзя (referenced_before_declaration).
    final socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .setReconnectionAttempts(-1)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(30000)
          .build(),
    );
    socket
      ..onConnect((_) {
        _connecting = false;
        _serverDisconnectAttempts = 0;
        _logger.d('WS /chats connected');
        _connectedController.add(true);
        // Re-join во все чаты, на которые подписаны до disconnect.
        // Без этого после reconnect клиент не получает события чата.
        if (_joinedChats.isNotEmpty) {
          socket.emit('rooms:join', {'chatIds': _joinedChats.toList()});
          _logger.d('WS /chats re-join: ${_joinedChats.length} chat(s)');
        }
      })
      ..onDisconnect((reason) {
        // reason приходит из socket.io как:
        // 'io server disconnect' | 'transport close' | 'ping timeout' | etc.
        // 'io server disconnect' = бекенд сам закрыл (auth fail / kicked).
        // socket.io в этом случае НЕ пытается reconnect самостоятельно,
        // поэтому делаем это вручную с backoff. Транспортные disconnect
        // (transport close, ping timeout) socket.io обрабатывает сам.
        _logger.w('WS /chats disconnected: ${reason ?? "unknown"}');
        _connectedController.add(false);
        if (!_intentionallyClosed && reason == 'io server disconnect') {
          _scheduleServerReconnect();
        }
      })
      ..onConnectError((e) {
        _connecting = false;
        _logger.w('WS /chats connect error: $e');
      })
      ..onError((e) => _logger.w('WS /chats error: $e'));

    for (final event in const [
      SocketEvents.messageNew,
      SocketEvents.messageEdited,
      SocketEvents.messageDeleted,
      SocketEvents.messageRead,
      SocketEvents.presenceTyping,
      SocketEvents.participantAdded,
      SocketEvents.participantRemoved,
      SocketEvents.chatVisibilityToggled,
      SocketEvents.exportReady,
      SocketEvents.exportFailed,
      SocketEvents.notificationNew,
    ]) {
      socket.on(event, (payload) {
        _eventsController.add((event, payload));
      });
    }

    socket.connect();
    _socket = socket;
  }

  /// Подписка на чаты — backend ожидает `rooms:join` с массивом
  /// `chatIds` и ack-callback `{ ok: true|false, joined: [...] }`.
  /// Возвращает Future<bool> — успешен ли join (для UI-фидбэка).
  Future<bool> joinChat(String chatId) => joinChats([chatId]);

  Future<bool> joinChats(List<String> chatIds) async {
    final socket = _socket;
    if (socket == null || chatIds.isEmpty) return false;
    // Запоминаем chatIds — onConnect handler re-join'ит их после reconnect.
    _joinedChats.addAll(chatIds);
    final completer = Completer<bool>();
    socket.emitWithAck(
      'rooms:join',
      {'chatIds': chatIds},
      ack: (dynamic data) {
        final ok = data is Map && data['ok'] == true;
        if (!completer.isCompleted) completer.complete(ok);
      },
    );
    // Защита от подвисания: 5s timeout — если ack не пришёл,
    // считаем join не выполненным (но reconnect продолжит работу).
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );
  }

  Future<void> leaveChat(String chatId) => leaveChats([chatId]);

  Future<void> leaveChats(List<String> chatIds) async {
    final socket = _socket;
    _joinedChats.removeAll(chatIds);
    if (socket == null || chatIds.isEmpty) return;
    socket.emit('rooms:leave', {'chatIds': chatIds});
  }

  /// `presence:typing` (client → server) — backend требует поля
  /// `chatId` и `typing` (bool). Сервер бродкастит обратно `presence:typing`
  /// с `userId` всем кроме отправителя.
  void typing(String chatId, {required bool typing}) {
    _socket?.emit('presence:typing', {'chatId': chatId, 'typing': typing});
  }

  Future<void> disconnect() async {
    _intentionallyClosed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _serverDisconnectAttempts = 0;
    _socket?.dispose();
    _socket = null;
    _connecting = false;
    _joinedChats.clear();
    _connectedController.add(false);
  }

  void dispose() {
    _intentionallyClosed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _socket?.dispose();
    _socket = null;
    _connectedController.close();
    _eventsController.close();
  }

  /// `io server disconnect` означает, что бэкенд закрыл соединение
  /// (чаще всего из-за просроченного JWT). socket.io не reconnect-ит сам в
  /// этом сценарии, поэтому сбрасываем текущий socket и пробуем подключиться
  /// заново — dio-интерсептор к моменту следующего connect успеет обновить
  /// access-token. Backoff 1s → 30s, чтобы не флудить бэкенд.
  void _scheduleServerReconnect() {
    _reconnectTimer?.cancel();
    final attempt = _serverDisconnectAttempts;
    _serverDisconnectAttempts = (attempt + 1).clamp(0, 5);
    final delayMs = (1000 * (1 << attempt)).clamp(1000, 30000);
    _logger.d('WS /chats reconnect in ${delayMs}ms (attempt ${attempt + 1})');
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (_intentionallyClosed) return;
      // Полностью пересоздаём socket: токен мог обновиться, dispose снимает
      // все старые listeners и не оставляет «зомби»-сокет в памяти.
      _socket?.dispose();
      _socket = null;
      _connecting = false;
      await connect();
    });
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService(
    env: ref.read(appEnvProvider),
    storage: ref.read(secureStorageProvider),
    logger: ref.read(loggerProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
