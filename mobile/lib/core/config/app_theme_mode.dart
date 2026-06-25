import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart'
    show secureStorageProvider;

/// Текущий режим темы приложения. Источник истины: persisted secure_storage.
/// Этап 7.5 ROAD_TO_100.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    Future.microtask(_hydrate);
    return ThemeMode.light;
  }

  Future<void> _hydrate() async {
    final raw = await ref.read(secureStorageProvider).readThemeMode();
    state = _parse(raw);
  }

  ThemeMode _parse(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.light;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    final normalized = mode == ThemeMode.system ? ThemeMode.light : mode;
    if (state == normalized) return;
    final code = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'light',
    };
    await ref.read(secureStorageProvider).writeThemeMode(code);
    state = normalized;
  }
}
