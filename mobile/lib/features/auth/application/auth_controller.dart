import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/access/system_role.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_tokens.dart';

/// Состояние авторизации.
enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.activeRole,
    this.userId,
  });

  final AuthStatus status;
  final SystemRole? activeRole;
  final String? userId;

  AuthState copyWith({
    AuthStatus? status,
    SystemRole? activeRole,
    String? userId,
  }) => AuthState(
    status: status ?? this.status,
    activeRole: activeRole ?? this.activeRole,
    userId: userId ?? this.userId,
  );
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  static const _uuid = Uuid();

  @override
  AuthState build() => const AuthState();

  SecureStorage get _storage => ref.read(secureStorageProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  // Single-flight для logout. На старте приложения refresh-interceptor может
  // получить 401 от нескольких параллельных запросов (projects/me/legal/...)
  // и каждый раз вызвать onSessionExpired → logout(). Без флага мы делали 5+
  // дублирующихся `POST /api/auth/logout` подряд.
  Future<void>? _logoutInFlight;

  Future<void> bootstrap() async {
    final access = await _storage.readAccessToken();
    final roleRaw = await _storage.readActiveRole();
    if (access == null || access.isEmpty) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    // userId раньше жил только в RAM (login/register), при рестарте приложения
    // обнулялся — все RBAC-провайдеры, завязанные на `me`, ломались
    // (owner-fallback в invitableRolesProvider, myMembershipInProjectProvider
    // и т.д.). Источник истины — claim `sub` в access-токене (см.
    // backend/auth/token.service.ts AccessTokenPayload).
    state = AuthState(
      status: AuthStatus.authenticated,
      activeRole: SystemRole.fromString(roleRaw),
      userId: _decodeJwtSub(access),
    );
  }

  static String? _decodeJwtSub(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      final pad = (4 - payload.length % 4) % 4;
      if (pad > 0) payload = payload.padRight(payload.length + pad, '=');
      final decoded = utf8.decode(base64Url.decode(payload));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      final sub = json['sub'];
      return sub is String && sub.isNotEmpty ? sub : null;
    } catch (_) {
      return null;
    }
  }

  Future<String> _ensureDeviceId() async {
    final existing = await _storage.readDeviceId();
    if (existing != null && existing.isNotEmpty) return existing;
    final created = _uuid.v4();
    await _storage.writeDeviceId(created);
    return created;
  }

  /// Логин. Возвращает null на успех, [AuthFailure] на ошибку.
  Future<AuthFailure?> login({
    required String phone,
    required String password,
  }) async {
    try {
      final deviceId = await _ensureDeviceId();
      final result = await _repo.login(
        phone: phone,
        password: password,
        deviceId: deviceId,
      );
      await _persistTokens(result.tokens);
      final role = SystemRole.fromString(result.systemRole);
      if (role != null) await _storage.writeActiveRole(role.name);
      state = AuthState(
        status: AuthStatus.authenticated,
        activeRole: role,
        userId: result.userId,
      );
      // Регистрацию device-token на бэкенде выполняет FcmService — он
      // подписан на authControllerProvider и сделает POST /api/me/devices
      // с реальным FCM-токеном после флипа в authenticated.
      return null;
    } on AuthException catch (e) {
      return e.failure;
    } catch (_) {
      // PlatformException из flutter_secure_storage (BadPaddingException на
      // некоторых Android keystore), любой другой неожиданный сбой — отдаём
      // unknown, чтобы UI показал тост вместо молчаливого «ничего не
      // произошло». Без этого ловится только DioException через _call().
      return AuthFailure.unknown;
    }
  }

  /// Регистрация нового пользователя. Автоматически логинит.
  Future<AuthFailure?> register({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    required SystemRole role,
  }) async {
    if (!SystemRole.registerable.contains(role)) {
      return AuthFailure.validation;
    }
    try {
      await _ensureDeviceId();
      final result = await _repo.register(
        phone: phone,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role.name,
      );
      await _persistTokens(result.tokens);
      await _storage.writeActiveRole(role.name);
      state = AuthState(
        status: AuthStatus.authenticated,
        activeRole: role,
        userId: result.userId,
      );
      return null;
    } on AuthException catch (e) {
      return e.failure;
    }
  }

  Future<void> logout() {
    // Если logout уже идёт — переиспользуем активный Future вместо нового
    // запроса. Если уже unauthenticated — no-op.
    final inFlight = _logoutInFlight;
    if (inFlight != null) return inFlight;
    if (state.status == AuthStatus.unauthenticated) return Future.value();
    final future = _doLogout();
    _logoutInFlight = future;
    return future.whenComplete(() => _logoutInFlight = null);
  }

  Future<void> _doLogout() async {
    final refresh = await _storage.readRefreshToken();
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _repo.logout(refreshToken: refresh);
      } on AuthException {
        // Сервер мог ответить 401/400 — не критично, токены всё равно чистим.
      }
    }
    await _storage.clearAuth();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Используется только под Riverpod-флоу смены роли — `tokens`
  /// перевыпускаются бэком (`PUT /me/active-role`) с новой `systemRole`
  /// в JWT-payload. Без этой замены RBAC бы 403'ил все действия новой
  /// роли, так как старый access-токен по-прежнему сидит со старой.
  Future<void> setActiveRole(SystemRole role, AuthTokens tokens) async {
    await _persistTokens(tokens);
    await _storage.writeActiveRole(role.name);
    state = state.copyWith(activeRole: role);
  }

  Future<String> ensureDeviceId() => _ensureDeviceId();

  Future<void> _persistTokens(AuthTokens t) async {
    await _storage.writeAccessToken(t.accessToken);
    await _storage.writeRefreshToken(t.refreshToken);
  }
}
