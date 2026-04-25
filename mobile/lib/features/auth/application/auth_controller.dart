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
  }) =>
      AuthState(
        status: status ?? this.status,
        activeRole: activeRole ?? this.activeRole,
        userId: userId ?? this.userId,
      );
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  static const _uuid = Uuid();

  @override
  AuthState build() => const AuthState();

  SecureStorage get _storage => ref.read(secureStorageProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> bootstrap() async {
    final access = await _storage.readAccessToken();
    final roleRaw = await _storage.readActiveRole();
    if (access == null || access.isEmpty) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    state = AuthState(
      status: AuthStatus.authenticated,
      activeRole: SystemRole.fromString(roleRaw),
    );
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

  Future<void> logout() async {
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

  Future<void> setActiveRole(SystemRole role) async {
    await _storage.writeActiveRole(role.name);
    state = state.copyWith(activeRole: role);
  }

  Future<void> _persistTokens(AuthTokens t) async {
    await _storage.writeAccessToken(t.accessToken);
    await _storage.writeRefreshToken(t.refreshToken);
  }
}
