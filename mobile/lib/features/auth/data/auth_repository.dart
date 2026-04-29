import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_tokens.dart';
import '../domain/legal_document.dart';

class AuthException implements Exception {
  AuthException(this.failure, this.apiError);

  final AuthFailure failure;
  final ApiError apiError;

  @override
  String toString() => 'AuthException($failure, $apiError)';
}

/// Тонкая обёртка над Dio для auth/me/legal эндпоинтов.
/// Генерированный client не используется, т.к. Nest не эмитит response
/// schemas (всё Response<void>). Парсим вручную.
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<RegisterResult> register({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String language = 'ru',
  }) async {
    return _call(
      () async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/auth/register',
          data: {
            'phone': phone,
            'password': password,
            'firstName': firstName,
            'lastName': lastName,
            'role': role,
            'language': language,
          },
          options: Options(extra: {'noAuth': true}),
        );
        return RegisterResult.fromJson(r.data!);
      },
    );
  }

  Future<LoginResult> login({
    required String phone,
    required String password,
    required String deviceId,
  }) async {
    return _call(
      () async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/auth/login',
          data: {
            'phone': phone,
            'password': password,
            'deviceId': deviceId,
          },
          options: Options(extra: {'noAuth': true}),
        );
        return LoginResult.fromJson(r.data!);
      },
    );
  }

  Future<AuthTokens> refresh({
    required String refreshToken,
    required String deviceId,
  }) async {
    return _call(
      () async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/auth/refresh',
          data: {'refreshToken': refreshToken, 'deviceId': deviceId},
          options: Options(extra: {'noAuth': true}),
        );
        return AuthTokens.fromJson(r.data!);
      },
    );
  }

  Future<void> logout({required String refreshToken}) async {
    return _call(
      () async {
        await _dio.post<void>(
          '/api/auth/logout',
          data: {'refreshToken': refreshToken},
          options: Options(extra: {'noAuth': true}),
        );
      },
    );
  }

  Future<void> recoverySend({required String phone}) async {
    return _call(
      () async {
        await _dio.post<void>(
          '/api/auth/recovery/send',
          data: {'phone': phone},
          options: Options(extra: {'noAuth': true}),
        );
      },
    );
  }

  Future<void> recoveryVerify({
    required String phone,
    required String code,
  }) async {
    return _call(
      () async {
        await _dio.post<void>(
          '/api/auth/recovery/verify',
          data: {'phone': phone, 'code': code},
          options: Options(extra: {'noAuth': true}),
        );
      },
    );
  }

  Future<void> recoveryReset({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    return _call(
      () async {
        await _dio.post<void>(
          '/api/auth/recovery/reset',
          data: {
            'phone': phone,
            'code': code,
            'newPassword': newPassword,
          },
          options: Options(extra: {'noAuth': true}),
        );
      },
    );
  }

  Future<LegalDocument> legalGet(LegalKind kind) async {
    return _call(
      () async {
        // Endpoint mounted под /legal/{kind} (без /api prefix — см.
        // setGlobalPrefix exclude в backend main.ts). Accept:application/json
        // обязателен — иначе LegalPublicController отдаёт HTML, и Dio
        // падает на JSON-парсинге (юзер видит «Не удалось загрузить документ»).
        final r = await _dio.get<Map<String, dynamic>>(
          '/legal/${kind.apiValue}',
          options: Options(
            extra: {'noAuth': true},
            headers: {'Accept': 'application/json'},
          ),
        );
        return LegalDocument.fromJson(r.data!);
      },
    );
  }

  Future<Map<String, LegalAcceptanceStatus>> legalAcceptanceStatus() async {
    return _call(
      () async {
        final r = await _dio.get<dynamic>('/api/me/legal-acceptance');
        // Сервер возвращает map { kind: { required, accepted, version } }.
        // При нестандартном ответе (например, ошибка пробилась как 200) —
        // считаем что нет pending acceptance (контроллер ничего не покажет).
        final raw = r.data;
        if (raw is! Map<String, dynamic>) {
          return const <String, LegalAcceptanceStatus>{};
        }
        final result = <String, LegalAcceptanceStatus>{};
        raw.forEach((k, v) {
          if (v is Map<String, dynamic>) {
            result[k] = LegalAcceptanceStatus.fromJson(v);
          }
        });
        return result;
      },
    );
  }

  Future<void> legalAccept(LegalKind kind) async {
    return _call(
      () async {
        await _dio.post<void>(
          '/api/me/legal-acceptance',
          data: {'kind': kind.apiValue},
        );
      },
    );
  }

  Future<void> registerDevice({
    required String platform, // 'ios' | 'android'
    required String token,
  }) async {
    return _call(
      () async {
        await _dio.post<void>(
          '/api/me/devices',
          data: {'platform': platform, 'token': token},
        );
      },
    );
  }

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw AuthException(AuthFailure.fromApiError(api), api);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.read(dioProvider);
  return AuthRepository(dio);
});
