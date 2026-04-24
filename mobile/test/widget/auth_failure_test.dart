import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/core/error/api_error.dart';
import 'package:repair_control/features/auth/domain/auth_failure.dart';

void main() {
  group('AuthFailure.fromApiError', () {
    test('invalid_credentials', () {
      const e = ApiError(
        kind: ApiErrorKind.unauthorized,
        statusCode: 401,
        code: 'auth.invalid_credentials',
      );
      expect(AuthFailure.fromApiError(e), AuthFailure.invalidCredentials);
    });

    test('phone_in_use', () {
      const e = ApiError(
        kind: ApiErrorKind.conflict,
        statusCode: 409,
        code: 'auth.phone_in_use',
      );
      expect(AuthFailure.fromApiError(e), AuthFailure.phoneInUse);
    });

    test('login_blocked', () {
      const e = ApiError(
        kind: ApiErrorKind.rateLimited,
        statusCode: 429,
        code: 'auth.login_blocked',
        retryAfterSeconds: 300,
      );
      expect(AuthFailure.fromApiError(e), AuthFailure.blocked);
    });

    test('recovery_invalid_code', () {
      const e = ApiError(
        kind: ApiErrorKind.validation,
        statusCode: 400,
        code: 'auth.recovery_invalid_code',
      );
      expect(
        AuthFailure.fromApiError(e),
        AuthFailure.recoveryInvalidCode,
      );
    });

    test('recovery_expired', () {
      const e = ApiError(
        kind: ApiErrorKind.validation,
        statusCode: 400,
        code: 'auth.recovery_expired',
      );
      expect(AuthFailure.fromApiError(e), AuthFailure.recoveryExpired);
    });

    test('network by kind', () {
      const e = ApiError(
        kind: ApiErrorKind.network,
        statusCode: 0,
      );
      expect(AuthFailure.fromApiError(e), AuthFailure.network);
    });

    test('server by kind', () {
      const e = ApiError(
        kind: ApiErrorKind.server,
        statusCode: 500,
      );
      expect(AuthFailure.fromApiError(e), AuthFailure.server);
    });

    test('unknown code → unknown', () {
      const e = ApiError(
        kind: ApiErrorKind.unknown,
        statusCode: 418,
        code: 'teapot',
      );
      expect(AuthFailure.fromApiError(e), AuthFailure.unknown);
    });
  });
}
