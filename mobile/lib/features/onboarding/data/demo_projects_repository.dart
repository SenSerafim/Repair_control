import 'package:dio/dio.dart';

import '../../projects/data/projects_repository.dart';
import '../../projects/domain/membership.dart';
import '../../projects/domain/project.dart';
import 'demo_data.dart';

/// Mock-репозиторий для демо-тура. Возвращает canned data из [DemoData],
/// игнорируя любые сетевые вызовы. Активен только в `/tour` route через
/// override `projectsRepositoryProvider`.
class DemoProjectsRepository extends ProjectsRepository {
  DemoProjectsRepository() : super(Dio());

  @override
  Future<List<Project>> list({ProjectStatus? status, String? role}) async {
    if (status == ProjectStatus.archived) return const [];
    return [DemoData.project];
  }

  @override
  Future<Project> get(String projectId) async => DemoData.project;

  @override
  Future<Project> create({
    required String title,
    String? address,
    String? description,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    int? workBudget,
    int? materialsBudget,
  }) async =>
      DemoData.project;

  @override
  Future<Project> update(
    String projectId, {
    String? title,
    String? address,
    String? description,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    int? workBudget,
    int? materialsBudget,
  }) async =>
      DemoData.project;

  @override
  Future<Project> archive(String projectId) async => DemoData.project;

  @override
  Future<Project> restore(String projectId) async => DemoData.project;

  @override
  Future<Project> copy(String projectId, {String? newTitle}) async =>
      DemoData.project;

  @override
  Future<List<Membership>> members(String projectId) async => const [];

  @override
  Future<ProjectMemberUser?> searchUser(
    String projectId, {
    String? phone,
    String? email,
  }) async =>
      null;

  @override
  Future<void> invite({
    required String projectId,
    required String phone,
    required MembershipRole role,
  }) async {}
}
