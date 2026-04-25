import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';

/// Список локалей, поддерживаемых приложением (зеркало
/// `MaterialApp.supportedLocales`). RU — дефолт по ТЗ §5.6.
const _supported = {'ru', 'en'};
const _fallback = 'ru';

/// Текущая локаль приложения. Источник истины:
/// 1. Перед load — `_fallback` (сразу `Locale('ru')`).
/// 2. После hydrate — значение из `SecureStorage.readLocale()`.
/// 3. После Login/смены языка — обновляется через `setLocale(...)`.
final appLocaleProvider =
    NotifierProvider<AppLocaleNotifier, Locale>(AppLocaleNotifier.new);

class AppLocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    // Стартуем с дефолта, асинхронно подменяем после hydrate.
    Future.microtask(_hydrate);
    return const Locale(_fallback);
  }

  Future<void> _hydrate() async {
    final stored = await ref.read(secureStorageProvider).readLocale();
    if (stored != null && _supported.contains(stored)) {
      state = Locale(stored);
    }
  }

  /// Применить новую локаль и сохранить в secure storage.
  /// Безопасна к вызову многократно — если код тот же, ничего не делает.
  Future<void> setLocale(String code) async {
    if (!_supported.contains(code)) return;
    if (state.languageCode == code) return;
    await ref.read(secureStorageProvider).writeLocale(code);
    state = Locale(code);
  }
}
