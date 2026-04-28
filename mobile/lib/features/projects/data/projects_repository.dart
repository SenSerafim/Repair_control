import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../../core/error/api_error.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/membership.dart';
import '../domain/project.dart';

class ProjectsException implements Exception {
  ProjectsException(this.failure, this.apiError);
  final AuthFailure failure;
  final ApiError apiError;

  @override
  String toString() => 'ProjectsException($failure, $apiError)';
}

class ProjectsRepository {
  ProjectsRepository(this._dio);

  final Dio _dio;

  /// [role] — фильтр по активной роли (customer/representative/contractor/master/admin).
  /// Каждая роль ведёт себя как изолированный «аккаунт»: customer видит только
  /// свои (где он owner), foreman/master/representative — только проекты со
  /// своим membership этой роли. Если null — backend читает activeRole из БД.
  Future<List<Project>> list({ProjectStatus? status, String? role}) =>
      _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/projects',
          queryParameters: {
            if (status != null) 'status': status.name,
            if (role != null) 'role': role,
          },
        );
        return r.data!
            .map((e) => Project.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<Project> get(String projectId) => _call(() async {
        final r = await _dio.get<Map<String, dynamic>>(
          '/api/projects/$projectId',
        );
        return Project.parse(r.data!);
      });

  Future<Project> create({
    required String title,
    String? address,
    String? description,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    int? workBudget,
    int? materialsBudget,
  }) =>
      _call(() async {
        final body = <String, dynamic>{
          'title': title,
          if (address != null && address.isNotEmpty) 'address': address,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (plannedStart != null)
            'plannedStart': plannedStart.toIso8601String(),
          if (plannedEnd != null) 'plannedEnd': plannedEnd.toIso8601String(),
          if (workBudget != null) 'workBudget': workBudget,
          if (materialsBudget != null) 'materialsBudget': materialsBudget,
        };
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects',
          data: body,
        );
        return Project.parse(r.data!);
      });

  Future<Project> update(
    String projectId, {
    String? title,
    String? address,
    String? description,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    int? workBudget,
    int? materialsBudget,
  }) =>
      _call(() async {
        final body = <String, dynamic>{
          if (title != null) 'title': title,
          if (address != null) 'address': address,
          if (description != null) 'description': description,
          if (plannedStart != null)
            'plannedStart': plannedStart.toIso8601String(),
          if (plannedEnd != null) 'plannedEnd': plannedEnd.toIso8601String(),
          if (workBudget != null) 'workBudget': workBudget,
          if (materialsBudget != null) 'materialsBudget': materialsBudget,
        };
        final r = await _dio.patch<Map<String, dynamic>>(
          '/api/projects/$projectId',
          data: body,
        );
        return Project.parse(r.data!);
      });

  Future<Project> archive(String projectId) => _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/archive',
        );
        return Project.parse(r.data!);
      });

  Future<Project> restore(String projectId) => _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/restore',
        );
        return Project.parse(r.data!);
      });

  Future<Project> copy(String projectId, {String? newTitle}) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/api/projects/$projectId/copy',
          data: {if (newTitle != null) 'newTitle': newTitle},
        );
        return Project.parse(r.data!);
      });

  Future<List<Membership>> members(String projectId) => _call(() async {
        final r = await _dio.get<List<dynamic>>(
          '/api/projects/$projectId/members',
        );
        return r.data!
            .map((e) => Membership.parse(e as Map<String, dynamic>))
            .toList();
      });

  Future<ProjectMemberUser?> searchUser(
    String projectId, {
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

  Future<void> invite({
    required String projectId,
    required String phone,
    required MembershipRole role,
  }) =>
      _call(() async {
        await _dio.post<void>(
          '/api/projects/$projectId/invitations',
          data: {'phone': phone, 'role': role.name},
        );
      });

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final api = ApiError.fromDio(e);
      throw ProjectsException(AuthFailure.fromApiError(api), api);
    }
  }
}

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  return ProjectsRepository(ref.read(dioProvider));
});
