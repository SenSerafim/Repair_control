import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../config/app_providers.dart';

/// Тип действия, отложенного до появления сети.
enum OfflineActionKind {
  stepToggle,
  substepToggle,
  noteCreate,
  questionAnswer,
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
      _draining = false;
    }
  }

  Future<void> clear() async {
    _queue.clear();
    await _persist();
  }
}

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
