import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Добавляет заголовок Idempotency-Key для POST-эндпоинтов, где он
/// обязателен (payments, materials, exports). При retry того же запроса
/// (options.extra['idempotencyKey'] передан извне) — используется тот же ключ.
class IdempotencyInterceptor extends Interceptor {
  IdempotencyInterceptor();

  static const _uuid = Uuid();

  static const _idempotentPathFragments = <String>[
    '/api/projects/', // payments, materials, selfpurchases, tool-issuances
    '/api/payments/',
    '/api/materials/',
    '/api/exports',
    '/api/selfpurchases/',
    '/api/tool-issuances/',
  ];

  static const _idempotentEndings = <String>[
    '/payments',
    '/materials',
    '/exports',
    '/selfpurchases',
    '/tool-issuances',
  ];

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (_needsIdempotency(options)) {
      final existing = options.extra['idempotencyKey']?.toString();
      final key = existing ?? _uuid.v4();
      options.headers['Idempotency-Key'] = key;
      options.extra['idempotencyKey'] = key;
    }
    handler.next(options);
  }

  bool _needsIdempotency(RequestOptions o) {
    if (o.method.toUpperCase() != 'POST') return false;
    if (o.headers.containsKey('Idempotency-Key')) return false;
    final path = o.path;
    final matchFragment = _idempotentPathFragments.any(path.contains);
    final matchEnding = _idempotentEndings.any(path.endsWith);
    return matchFragment || matchEnding;
  }
}
