import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/config/app_providers.dart';
import '../domain/app_notification.dart';

/// Хранилище уведомлений на диск. JSON-файл, last-N=200 записей.
/// Drift не используем намеренно: одной таблицы недостаточно, чтобы
/// тащить кодогенерацию + миграции. Если появится вторая таблица —
/// переедем все вместе.
class NotificationsStore {
  NotificationsStore({required Logger logger, File? file})
      : _logger = logger,
        _file = file;

  static const _fileName = 'notifications.json';
  static const _maxItems = 200;

  final Logger _logger;
  File? _file;

  Future<File> _resolveFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationSupportDirectory();
    _file = File('${dir.path}/$_fileName');
    return _file!;
  }

  Future<List<AppNotification>> load() async {
    try {
      final f = await _resolveFile();
      if (!f.existsSync()) return const [];
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return const [];
      // Newest first.
      return (jsonDecode(raw) as List)
          .map((e) => _fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    } catch (e, st) {
      _logger.w('NotificationsStore.load failed', error: e, stackTrace: st);
      return const [];
    }
  }

  Future<void> save(List<AppNotification> items) async {
    try {
      final f = await _resolveFile();
      final trimmed = items.length > _maxItems
          ? items.sublist(0, _maxItems)
          : items;
      final raw = jsonEncode(trimmed.map(_toJson).toList());
      await f.writeAsString(raw, flush: true);
    } catch (e, st) {
      _logger.w('NotificationsStore.save failed', error: e, stackTrace: st);
    }
  }

  static Map<String, dynamic> _toJson(AppNotification n) => {
        'id': n.id,
        'kind': n.kind,
        'title': n.title,
        'body': n.body,
        'data': n.data,
        'receivedAt': n.receivedAt.toIso8601String(),
        'read': n.read,
      };

  static AppNotification _fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        kind: j['kind'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        data: Map<String, dynamic>.from(j['data'] as Map? ?? const {}),
        receivedAt: DateTime.parse(j['receivedAt'] as String),
        read: j['read'] as bool? ?? false,
      );
}

final notificationsStoreProvider = Provider<NotificationsStore>((ref) {
  return NotificationsStore(logger: ref.read(loggerProvider));
});
