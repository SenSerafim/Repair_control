import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/knowledge_article.dart';
import '../domain/knowledge_category.dart';
import '../domain/knowledge_search_hit.dart';

class KnowledgeException implements Exception {
  KnowledgeException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;

  @override
  String toString() => 'KnowledgeException($failure, $apiError)';
}

class KnowledgeRepository {
  KnowledgeRepository(this._dio);

  final Dio _dio;

  /// In-memory ETag-кеш статей. Сбрасывается на refresh либо переподключении.
  final Map<String, KnowledgeArticle> _articleCache = {};

  Future<List<KnowledgeCategory>> listCategories({
    KnowledgeCategoryScope? scope,
    String? moduleSlug,
  }) =>
      _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/knowledge/categories',
          queryParameters: {
            if (scope != null)
              'scope':
                  scope == KnowledgeCategoryScope.global ? 'global' : 'project_module',
            if (moduleSlug != null) 'moduleSlug': moduleSlug,
          },
        );
        return r.data!
            .map((e) => KnowledgeCategory.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<KnowledgeCategoryDetail> getCategory(String id) => _call(() async {
        final r = await _dio.get<Map<String, dynamic>>(
          '/api/knowledge/categories/$id',
        );
        return KnowledgeCategoryDetail.parse(r.data!);
      });

  Future<KnowledgeArticle> getArticle(String id) => _call(() async {
        final cached = _articleCache[id];
        final r = await _dio.get<Map<String, dynamic>?>(
          '/api/knowledge/articles/$id',
          options: Options(
            headers: {
              if (cached != null) 'If-None-Match': '"${cached.etag}"',
            },
            validateStatus: (s) => s != null && s < 500 && s != 404,
          ),
        );
        if (r.statusCode == 304 && cached != null) {
          return cached;
        }
        final article = KnowledgeArticle.parse(r.data!);
        _articleCache[id] = article;
        return article;
      });

  /// Presigned download URL для media-asset (видео streaming).
  Future<String> getAssetUrl(String articleId, String assetId) =>
      _call(() async {
        final r = await _dio.get<Map<String, dynamic>>(
          '/api/knowledge/articles/$articleId/assets/$assetId/url',
        );
        return r.data!['url'] as String;
      });

  Future<List<KnowledgeSearchHit>> search(
    String query, {
    int limit = 20,
    KnowledgeCategoryScope? scope,
    String? moduleSlug,
  }) =>
      _call(() async {
        final r = await _dio.get<Map<String, dynamic>>(
          '/api/knowledge/search',
          queryParameters: {
            'q': query,
            'limit': limit,
            if (scope != null)
              'scope':
                  scope == KnowledgeCategoryScope.global ? 'global' : 'project_module',
            if (moduleSlug != null) 'moduleSlug': moduleSlug,
          },
        );
        final hits = (r.data?['hits'] as List<dynamic>? ?? const [])
            .map((e) => KnowledgeSearchHit.parse(e as Map<String, dynamic>))
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
      throw KnowledgeException(AuthFailure.fromApiError(api), api);
    }
  }
}

final knowledgeRepositoryProvider = Provider<KnowledgeRepository>(
  (ref) => KnowledgeRepository(ref.read(dioProvider)),
);
