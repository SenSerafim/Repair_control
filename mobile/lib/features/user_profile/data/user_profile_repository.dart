import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/user_profile_aggregate.dart';

class UserProfileException implements Exception {
  UserProfileException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

class UserProfileRepository {
  UserProfileRepository(this._dio);
  final Dio _dio;

  Future<UserProfileAggregate> get(String userId) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '/api/users/$userId/profile-aggregate',
      );
      return UserProfileAggregate.parse(r.data!);
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw UserProfileException(AuthFailure.fromApiError(api), api);
    }
  }
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(ref.read(dioProvider));
});

final userProfileAggregateProvider =
    FutureProvider.family<UserProfileAggregate, String>((ref, userId) async {
  return ref.read(userProfileRepositoryProvider).get(userId);
});
