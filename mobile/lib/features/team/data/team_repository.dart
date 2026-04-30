import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../../projects/domain/membership.dart';
import '../domain/invitation.dart';

class TeamException implements Exception {
  TeamException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;
}

/// Группа «проект + участники» для агрегированного экрана «Команда»
/// (mobile-таб). Возвращается из `GET /api/me/teammates`.
class TeammateGroup {
  const TeammateGroup({
    required this.projectId,
    required this.projectTitle,
    required this.ownerId,
    this.owner,
    required this.members,
  });

  final String projectId;
  final String projectTitle;
  final String ownerId;
  final ProjectMemberUser? owner;
  final List<Membership> members;
}

/// Объединяет members + invitations endpoints из projects.controller.
/// Раздельный provider от ProjectsRepository — т.к. команда отдельное
/// UX-пространство.
class TeamRepository {
  TeamRepository(this._dio);

  final Dio _dio;

  Future<List<Membership>> members(String projectId) =>
      _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/projects/$projectId/members',
        );
        return r.data!
            .map((e) => Membership.parse(e as Map<String, dynamic>))
            .toList();
      });

  /// Все «соратники» пользователя через все его активные проекты.
  /// Возвращает массив групп `{ project, owner, members }` —
  /// для рендеринга на mobile-табе «Команда» с группировкой по проекту.
  Future<List<TeammateGroup>> listTeammates() => _call(() async {
        final r = await _dio.get<List<dynamic>>('/api/me/teammates');
        return r.data!.map((raw) {
          final m = raw as Map<String, dynamic>;
          final project = m['project'] as Map<String, dynamic>;
          final owner = m['owner'] as Map<String, dynamic>?;
          final members = (m['members'] as List<dynamic>? ?? const [])
              .map((e) => Membership.parse(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList();
          return TeammateGroup(
            projectId: project['id'] as String,
            projectTitle: (project['title'] as String?) ?? '',
            ownerId: (project['ownerId'] as String?) ?? '',
            owner: owner == null ? null : ProjectMemberUser.parse(owner),
            members: members,
          );
        }).toList();
      });

  Future<Membership> addMember({
    required String projectId,
    required String userId,
    required MembershipRole role,
    Map<String, bool>? permissions,
    List<String>? stageIds,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/members',
          data: {
            'userId': userId,
            'role': role.name,
            if (permissions != null) 'permissions': permissions,
            if (stageIds != null) 'stageIds': stageIds,
          },
        );
        return Membership.parse(r.data!);
      });

  Future<Membership> updateMember({
    required String projectId,
    required String membershipId,
    Map<String, bool>? permissions,
    List<String>? stageIds,
  }) =>
      _call(() async {
        final r = await _dio.patch<Map<String, dynamic>>(
          '/api/projects/$projectId/members/$membershipId',
          data: {
            if (permissions != null) 'permissions': permissions,
            if (stageIds != null) 'stageIds': stageIds,
          },
        );
        return Membership.parse(r.data!);
      });

  Future<void> removeMember({
    required String projectId,
    required String membershipId,
  }) =>
      _call(() async {
        await _dio.delete<void>(
          '/api/projects/$projectId/members/$membershipId',
        );
      });

  Future<ProjectMemberUser?> searchUser({
    required String projectId,
    String? phone,
    String? email,
  }) =>
      _call(() async {
        final r = await _dio.get<Map<String, dynamic>?>(
          '/api/projects/$projectId/search-user',
          queryParameters: {
            if (phone != null) 'phone': phone,
            if (email != null) 'email': email,
          },
        );
        final data = r.data;
        if (data == null || data.isEmpty) return null;
        return ProjectMemberUser.parse(data);
      });

  Future<List<Invitation>> listInvitations(String projectId) =>
      _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/projects/$projectId/invitations',
        );
        return r.data!
            .map((e) => Invitation.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<Invitation> invite({
    required String projectId,
    required String phone,
    required MembershipRole role,
  }) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/invitations',
          data: {'phone': phone, 'role': role.name},
        );
        return Invitation.parse(r.data!);
      });

  Future<void> cancelInvitation({
    required String projectId,
    required String invitationId,
  }) =>
      _call(() async {
        await _dio.delete<void>(
          '/api/projects/$projectId/invitations/$invitationId',
        );
      });

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw TeamException(AuthFailure.fromApiError(api), api);
    }
  }
}

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository(ref.read(dioProvider));
});

/// Агрегированный список «команда из всех моих проектов» —
/// для mobile-таба «Команда».
final myTeammatesProvider =
    FutureProvider<List<TeammateGroup>>((ref) async {
  return ref.read(teamRepositoryProvider).listTeammates();
});
