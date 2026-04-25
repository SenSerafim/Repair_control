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
  final _connectedController = StreamController<bool>.broadcast();
  final _eventsController =
      StreamController<(String event, dynamic payload)>.broadcast();

  Stream<bool> get connectedStream => _connectedController.stream;
  Stream<(String, dynamic)> get eventsStream => _eventsController.stream;

  /// Фильтрованный поток по имени события.
  Stream<dynamic> on(String event) =>
      eventsStream.where((t) => t.$1 == event).map((t) => t.$2);

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null) return;
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) return;

    final url = '${_env.wsUrl}/chats';
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
    )
      ..onConnect((_) {
        _logger.d('WS /chats connected');
        _connectedController.add(true);
      })
      ..onDisconnect((_) {
        _logger.d('WS /chats disconnected');
        _connectedController.add(false);
      })
      ..onConnectError((e) => _logger.w('WS /chats connect error: $e'))
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
    _socket?.dispose();
    _socket = null;
    _connectedController.add(false);
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    _connectedController.close();
    _eventsController.close();
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
