import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/feed_event.dart';

class FeedException implements Exception {
  FeedException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

class FeedPage {
  const FeedPage({required this.items, this.nextCursor});
  final List<FeedEvent> items;
  final String? nextCursor;
}

class FeedRepository {
  FeedRepository(this._dio);
  final Dio _dio;

  Future<FeedPage> list({
    required String projectId,
    String? cursor,
    int limit = 50,
    List<String>? kinds,
    String? stageId,
    String? actorId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) =>
      _call(() async {
        final r = await _dio.get<dynamic>(
          '/api/projects/$projectId/feed',
          queryParameters: {
            if (cursor != null) 'cursor': cursor,
            'limit': limit,
            if (kinds != null && kinds.isNotEmpty) 'kind': kinds,
            if (stageId != null) 'stageId': stageId,
            if (actorId != null) 'actorId': actorId,
            if (dateFrom != null) 'dateFrom': dateFrom.toIso8601String(),
            if (dateTo != null) 'dateTo': dateTo.toIso8601String(),
          },
        );
        final data = r.data;
        if (data is Map<String, dynamic>) {
          return FeedPage(
            items: (data['items'] as List<dynamic>? ?? const [])
                .map((e) => FeedEvent.parse(e as Map<String, dynamic>))
                .toList(),
            nextCursor: data['nextCursor'] as String?,
          );
        }
        if (data is List) {
          return FeedPage(
            items: data
                .map((e) => FeedEvent.parse(e as Map<String, dynamic>))
                .toList(),
          );
        }
        return const FeedPage(items: []);
      });

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw FeedException(AuthFailure.fromApiError(api), api);
    }
  }
}

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.read(dioProvider));
});
