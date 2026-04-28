import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/methodology.dart';

class MethodologyException implements Exception {
  MethodologyException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

class MethodologyRepository {
  MethodologyRepository(this._dio);

  final Dio _dio;

  /// In-memory ETag-кеш статей.
  final Map<String, MethodologyArticle> _articleCache = {};

  Future<List<MethodologySection>> listSections() => _call(() async {
        final r =
            await _dio.get<List<dynamic>>('/api/methodology/sections');
        return r.data!
            .map((e) => MethodologySection.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<MethodologySection> getSection(String id) => _call(() async {
        final r = await _dio.get<Map<String, dynamic>>(
          '/api/methodology/sections/$id',
        );
        return MethodologySection.parse(r.data!);
      });

  /// Загрузка статьи с ETag-caching: If-None-Match → 304 → возвращаем cached.
  /// При 200 обновляем кеш свежей версией.
  Future<MethodologyArticle> getArticle(String id) => _call(() async {
        final cached = _articleCache[id];
        final r = await _dio.get<Map<String, dynamic>?>(
          '/api/methodology/articles/$id',
          options: Options(
            headers: {
              if (cached != null) 'If-None-Match': cached.etag,
            },
            // По умолчанию Dio считает 304 ошибкой; приняли 200 и 304
            validateStatus: (s) => s != null && s < 500 && s != 404,
          ),
        );
        if (r.statusCode == 304 && cached != null) {
          return cached;
        }
        final article = MethodologyArticle.parse(r.data!);
        _articleCache[id] = article;
        return article;
      });

  Future<List<MethodologySearchHit>> search(
    String query, {
    int limit = 20,
  }) =>
      _call(() async {
        final r = await _dio.get<Map<String, dynamic>>(
          '/api/methodology/search',
          queryParameters: {'q': query, 'limit': limit},
        );
        final hits = (r.data?['hits'] as List<dynamic>? ?? const [])
            .map((e) =>
                MethodologySearchHit.parse(e as Map<String, dynamic>))
            .toList();
        return hits;
      });

  void invalidateCache() {
    _articleCache.clear();
  }

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw MethodologyException(AuthFailure.fromApiError(api), api);
    }
  }
}

final methodologyRepositoryProvider =
    Provider<MethodologyRepository>((ref) {
  return MethodologyRepository(ref.read(dioProvider));
});
