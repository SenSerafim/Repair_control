import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/core/network/interceptors/idempotency_interceptor.dart';

/// Phase 11: контракт IdempotencyInterceptor — `Idempotency-Key` header
/// добавляется только для финансовых / материальных / экспортных POST'ов
/// (как требует backend), и при retry того же запроса используется
/// тот же ключ (через `options.extra['idempotencyKey']`).
void main() {
  late IdempotencyInterceptor interceptor;

  setUp(() {
    interceptor = IdempotencyInterceptor();
  });

  /// Прогоняет options через onRequest, возвращает финальный header-ключ.
  String? runRequest(RequestOptions options) {
    interceptor.onRequest(options, RequestInterceptorHandler());
    return options.headers['Idempotency-Key'] as String?;
  }

  group('Add Idempotency-Key header', () {
    test('POST /api/projects/p1/payments — добавляет ключ', () {
      final opts = RequestOptions(
        method: 'POST',
        path: '/api/projects/p1/payments',
      );
      final key = runRequest(opts);
      expect(key, isNotNull);
      expect(key!.length, greaterThan(20)); // UUID
    });

    test('POST /api/payments/p1/distribute — добавляет ключ', () {
      final opts = RequestOptions(
        method: 'POST',
        path: '/api/payments/p1/distribute',
      );
      expect(runRequest(opts), isNotNull);
    });

    test('POST /api/projects/p1/selfpurchases — добавляет ключ', () {
      final opts = RequestOptions(
        method: 'POST',
        path: '/api/projects/p1/selfpurchases',
      );
      expect(runRequest(opts), isNotNull);
    });

    test('POST /api/projects/p1/materials — добавляет ключ', () {
      final opts = RequestOptions(
        method: 'POST',
        path: '/api/projects/p1/materials',
      );
      expect(runRequest(opts), isNotNull);
    });

    test('POST /api/projects/p1/exports — добавляет ключ', () {
      final opts = RequestOptions(
        method: 'POST',
        path: '/api/projects/p1/exports',
      );
      expect(runRequest(opts), isNotNull);
    });
  });

  group('Не добавляет Idempotency-Key', () {
    test('GET — не добавляет', () {
      final opts = RequestOptions(
        method: 'GET',
        path: '/api/projects/p1/payments',
      );
      expect(runRequest(opts), isNull);
    });

    test('POST на не-финансовый endpoint — не добавляет', () {
      final opts = RequestOptions(
        method: 'POST',
        path: '/api/auth/login',
      );
      expect(runRequest(opts), isNull);
    });

    test('PATCH — не добавляет', () {
      final opts = RequestOptions(
        method: 'PATCH',
        path: '/api/projects/p1/payments',
      );
      expect(runRequest(opts), isNull);
    });
  });

  group('Retry использует тот же ключ', () {
    test('options.extra[idempotencyKey] переиспользуется', () {
      const externalKey = 'fixed-test-uuid-1234';
      final opts = RequestOptions(
        method: 'POST',
        path: '/api/projects/p1/payments',
        extra: {'idempotencyKey': externalKey},
      );
      final key = runRequest(opts);
      expect(key, externalKey);
    });

    test('Existing Idempotency-Key header не перезаписывается', () {
      const existing = 'pre-existing-key';
      final opts = RequestOptions(
        method: 'POST',
        path: '/api/projects/p1/payments',
        headers: {'Idempotency-Key': existing},
      );
      runRequest(opts);
      expect(opts.headers['Idempotency-Key'], existing);
    });
  });
}
