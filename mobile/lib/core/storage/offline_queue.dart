import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../config/app_providers.dart';
import '../error/api_error.dart';

/// Тип действия, отложенного до появления сети.
///
/// При расширении набора — обязательно зарегистрировать handler в
/// `offline_handlers.dart#registerOfflineHandlers`. Иначе действие
/// вылетит из очереди как «без handler'а» при первом drain.
enum OfflineActionKind {
  stepToggle,
  substepToggle,
  noteCreate,
  questionAnswer,
  stagePause,
  stageResume,
  paymentDispute,
  selfpurchaseCreate,
  materialMarkBought,
}

class OfflineAction {
  OfflineAction({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
  });

  factory OfflineAction.fromJson(Map<String, dynamic> j) => OfflineAction(
        id: j['id'] as String,
        kind: OfflineActionKind.values.firstWhere(
          (k) => k.name == j['kind'],
          orElse: () => OfflineActionKind.stepToggle,
        ),
        payload: Map<String, dynamic>.from(j['payload'] as Map),
        createdAt: DateTime.parse(j['createdAt'] as String),
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final OfflineActionKind kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;

  OfflineAction copyWith({int? attempts}) => OfflineAction(
        id: id,
        kind: kind,
        payload: payload,
        createdAt: createdAt,
        attempts: attempts ?? this.attempts,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
      };
}

typedef OfflineHandler = Future<void> Function(OfflineAction action);

/// Сигнал UI про state-конфликт при drain offline-очереди.
class OfflineConflict {
  const OfflineConflict({
    required this.kind,
    required this.payload,
    this.error,
  });

  final OfflineActionKind kind;
  final Map<String, dynamic> payload;
  final ApiError? error;

  String get userMessage {
    final code = error?.code;
    if (code != null) {
      return 'Сервер изменил состояние ($code), перезагрузите экран';
    }
    return 'Сервер изменил состояние, перезагрузите экран';
  }
}

/// Проверка: была ли это конфликт-ошибка от сервера, retry которой
/// бесполезен (state changed, stale, conflict).
bool _isStateConflict(Object e) {
  if (e is ApiError) {
    if (e.kind == ApiErrorKind.conflict) return true;
    final code = e.code;
    if (code == 'state_conflict' ||
        code == 'stale_state' ||
        code == 'stages.invalid_transition' ||
        code == 'steps.invalid_status' ||
        code == 'payments.invalid_status') {
      return true;
    }
    return false;
  }
  if (e is DioException) {
    final s = e.response?.statusCode ?? 0;
    return s == 409;
  }
  return false;
}

/// Простой offline-воркер: складывает действия в JSON-файл,
/// при появлении сети дропает очередь через зарегистрированные handlers.
class OfflineQueue {
  OfflineQueue({required Logger logger, File? file})
      : _logger = logger,
        _file = file;

  static const _uuid = Uuid();
  static const _fileName = 'offline_queue.json';

  final Logger _logger;
  File? _file;
  final List<OfflineAction> _queue = [];
  final Map<OfflineActionKind, OfflineHandler> _handlers = {};
  bool _draining = false;
  bool _loaded = false;

  /// Сигнализирует UI, что drain дропнул action из-за state-конфликта
  /// (server-state изменился, retry смысла не имеет — gaps §2.4).
  /// UI подписывается через `conflictsProvider` и показывает Toast.
  final StreamController<OfflineConflict> _conflicts =
      StreamController<OfflineConflict>.broadcast();
  Stream<OfflineConflict> get conflicts => _conflicts.stream;

  List<OfflineAction> get pending => List.unmodifiable(_queue);

  Future<File> _resolveFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationSupportDirectory();
    _file = File('${dir.path}/$_fileName');
    return _file!;
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final f = await _resolveFile();
      if (!f.existsSync()) {
        _loaded = true;
        return;
      }
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) {
        _loaded = true;
        return;
      }
      final list = (jsonDecode(raw) as List)
          .map((e) => OfflineAction.fromJson(e as Map<String, dynamic>))
          .toList();
      _queue
        ..clear()
        ..addAll(list);
    } catch (e, st) {
      _logger.w('OfflineQueue.load failed', error: e, stackTrace: st);
    } finally {
      _loaded = true;
    }
  }

  Future<void> _persist() async {
    try {
      final f = await _resolveFile();
      final raw = jsonEncode(_queue.map((a) => a.toJson()).toList());
      await f.writeAsString(raw, flush: true);
    } catch (e, st) {
      _logger.w('OfflineQueue.persist failed', error: e, stackTrace: st);
    }
  }

  void registerHandler(OfflineActionKind kind, OfflineHandler h) {
    _handlers[kind] = h;
  }

  /// Подписчики обновляются при `enqueue`/`drain` — нужен `pendingCount`
  /// в UI (`OfflineSyncBanner`). Простой StreamController вместо
  /// ChangeNotifier — не тащим Flutter в core/storage.
  final _pendingController = StreamController<int>.broadcast();
  Stream<int> get pendingCountStream => _pendingController.stream;
  int get pendingCount => _queue.length;

  void _emitPending() => _pendingController.add(_queue.length);

  Future<OfflineAction> enqueue({
    required OfflineActionKind kind,
    required Map<String, dynamic> payload,
  }) async {
    final action = OfflineAction(
      id: _uuid.v4(),
      kind: kind,
      payload: payload,
      createdAt: DateTime.now(),
    );
    _queue.add(action);
    await _persist();
    _emitPending();
    return action;
  }

  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_queue.isNotEmpty) {
        final action = _queue.first;
        final handler = _handlers[action.kind];
        if (handler == null) {
          _logger.w('OfflineQueue: no handler for ${action.kind}');
          _queue.removeAt(0);
          continue;
        }
        try {
          await handler(action);
          _queue.removeAt(0);
        } catch (e, st) {
          // Конфликт состояния: сервер уже изменил resource (например,
          // stage уже не в нужном статусе) → retry бесполезен.
          // Дропаем action и сигналим UI о необходимости перезагрузки.
          if (_isStateConflict(e)) {
            _logger.w(
              'OfflineQueue.drain: state conflict on ${action.kind} → drop',
              error: e,
            );
            _queue.removeAt(0);
            _conflicts.add(
              OfflineConflict(
                kind: action.kind,
                payload: action.payload,
                error: e is ApiError ? e : null,
              ),
            );
            continue;
          }
          _logger.w(
            'OfflineQueue.drain: handler failed (${action.kind})',
            error: e,
            stackTrace: st,
          );
          final bumped = action.copyWith(attempts: action.attempts + 1);
          _queue[0] = bumped;
          if (bumped.attempts >= 5) {
            _logger.e(
              'OfflineQueue: drop ${action.kind} after 5 attempts',
              error: e,
            );
            _queue.removeAt(0);
          } else {
            break; // пробуем позже
          }
        }
      }
    } finally {
      await _persist();
      _emitPending();
      _draining = false;
    }
  }

  Future<void> clear() async {
    _queue.clear();
    await _persist();
    _emitPending();
  }
}

/// Поток с числом отложенных действий — для in-app `OfflineSyncBanner`.
final offlinePendingCountProvider = StreamProvider<int>((ref) {
  final queue = ref.watch(offlineQueueProvider);
  return queue.pendingCountStream;
});

/// Поток конфликтов offline-drain — UI слушает и показывает Toast.
final offlineConflictsProvider = StreamProvider<OfflineConflict>((ref) {
  final queue = ref.watch(offlineQueueProvider);
  return queue.conflicts;
});

final offlineQueueProvider = Provider<OfflineQueue>((ref) {
  return OfflineQueue(logger: ref.read(loggerProvider));
});

/// Подписка на connectivityProvider — при переходе online дропаем очередь.
final offlineQueueDrainProvider = Provider<void>((ref) {
  final q = ref.watch(offlineQueueProvider);
  ref.listen(connectivityProvider, (_, next) {
    if (next.value == ConnectivityStatus.online) {
      unawaited(q.drain());
    }
  });
});
