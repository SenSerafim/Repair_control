import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Обёртка над flutter_secure_storage для токенов, device-id, active-role.
/// Все ключи централизованы здесь, чтобы избежать опечаток.
class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _kAccess = 'auth.accessToken';
  static const _kRefresh = 'auth.refreshToken';
  static const _kDeviceId = 'auth.deviceId';
  static const _kActiveRole = 'auth.activeRole';
  static const _kLocale = 'app.locale';
  static const _kThemeMode = 'app.themeMode';

  Future<String?> readAccessToken() => _storage.read(key: _kAccess);
  Future<void> writeAccessToken(String value) =>
      _storage.write(key: _kAccess, value: value);

  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);
  Future<void> writeRefreshToken(String value) =>
      _storage.write(key: _kRefresh, value: value);

  Future<String?> readDeviceId() => _storage.read(key: _kDeviceId);
  Future<void> writeDeviceId(String value) =>
      _storage.write(key: _kDeviceId, value: value);

  Future<String?> readActiveRole() => _storage.read(key: _kActiveRole);
  Future<void> writeActiveRole(String value) =>
      _storage.write(key: _kActiveRole, value: value);
  Future<void> clearActiveRole() => _storage.delete(key: _kActiveRole);

  /// Сохранённый язык интерфейса (`'ru'` / `'en'`). Берётся при старте
  /// приложения до того, как профиль с сервера загрузится — чтобы UI
  /// сразу показывался на правильном языке.
  Future<String?> readLocale() => _storage.read(key: _kLocale);
  Future<void> writeLocale(String code) =>
      _storage.write(key: _kLocale, value: code);

  /// Тема (system / light / dark). Этап 7.5 ROAD_TO_100.
  Future<String?> readThemeMode() => _storage.read(key: _kThemeMode);
  Future<void> writeThemeMode(String mode) =>
      _storage.write(key: _kThemeMode, value: mode);

  Future<void> clearAuth() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kActiveRole);
  }
}
