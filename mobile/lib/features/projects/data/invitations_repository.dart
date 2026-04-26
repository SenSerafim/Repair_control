import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/membership.dart';

class InvitationsException implements Exception {
  InvitationsException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

/// Сгенерированный код приглашения.
class InviteCode {
  const InviteCode({
    required this.id,
    required this.token,
    required this.role,
    required this.stageIds,
    required this.expiresAt,
  });

  factory InviteCode.fromJson(Map<String, dynamic> json) => InviteCode(
        id: json['id'] as String,
        token: json['token'] as String,
        role: MembershipRole.fromString(json['role'] as String?),
        stageIds: (json['stageIds'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );

  final String id;
  final String token;
  final MembershipRole role;
  final List<String> stageIds;
  final DateTime expiresAt;
}

/// Результат join-by-code.
class JoinByCodeResult {
  const JoinByCodeResult({required this.projectId, required this.role});
  final String projectId;
  final MembershipRole role;
}

class InvitationsRepository {
  InvitationsRepository(this._dio);
  final Dio _dio;

  /// POST /api/projects/:projectId/invitations/generate-code
  Future<InviteCode> generateCode({
    required String projectId,
    required MembershipRole role,
    Map<String, bool>? permissions,
    List<String>? stageIds,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/invitations/generate-code',
          data: {
            'role': role.name,
            if (permissions != null) 'permissions': permissions,
            if (stageIds != null) 'stageIds': stageIds,
          },
        );
        return InviteCode.fromJson(r.data!);
      });

  /// POST /api/projects/join-by-code
  Future<JoinByCodeResult> joinByCode(String code) => _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/join-by-code',
          data: {'code': code},
        );
        final membership = (r.data!['membership'] as Map<String, dynamic>?) ?? {};
        return JoinByCodeResult(
          projectId: r.data!['projectId'] as String,
          role: MembershipRole.fromString(membership['role'] as String?),
        );
      });

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw InvitationsException(AuthFailure.fromApiError(api), api);
    }
  }
}

final invitationsRepositoryProvider = Provider<InvitationsRepository>((ref) {
  return InvitationsRepository(ref.read(dioProvider));
});
