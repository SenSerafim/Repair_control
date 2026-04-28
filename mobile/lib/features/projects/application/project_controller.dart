import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_failure.dart';
import '../data/projects_repository.dart';
import '../domain/project.dart';
import 'projects_list_controller.dart';

/// Кеш отдельного проекта. Family по projectId.
final projectControllerProvider =
    AsyncNotifierProvider.family<ProjectController, Project, String>(
  ProjectController.new,
);

class ProjectController extends FamilyAsyncNotifier<Project, String> {
  @override
  Future<Project> build(String projectId) async {
    return ref.read(projectsRepositoryProvider).get(projectId);
  }

  Future<AuthFailure?> save({
    String? title,
    String? address,
    String? description,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    int? workBudget,
    int? materialsBudget,
  }) async {
    try {
      final updated =
          await ref.read(projectsRepositoryProvider).update(
                arg,
                title: title,
                address: address,
                description: description,
                plannedStart: plannedStart,
                plannedEnd: plannedEnd,
                workBudget: workBudget,
                materialsBudget: materialsBudget,
              );
      state = AsyncData(updated);
      ref.read(activeProjectsProvider.notifier).replaceUpdated(updated);
      return null;
    } on ProjectsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> archive() async {
    try {
      final p = await ref.read(projectsRepositoryProvider).archive(arg);
      state = AsyncData(p);
      ref
        ..invalidate(activeProjectsProvider)
        ..invalidate(archivedProjectsProvider);
      return null;
    } on ProjectsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> restore() async {
    try {
      final p = await ref.read(projectsRepositoryProvider).restore(arg);
      state = AsyncData(p);
      ref
        ..invalidate(activeProjectsProvider)
        ..invalidate(archivedProjectsProvider);
      return null;
    } on ProjectsException catch (e) {
      return e.failure;
    }
  }
}

/// Глобальный провайдер для создания нового проекта и копирования.
final projectCreatorProvider = Provider<ProjectCreator>(ProjectCreator.new);

class ProjectCreator {
  ProjectCreator(this._ref);

  final Ref _ref;

  Future<Project> create({
    required String title,
    String? address,
    String? description,
    DateTime? plannedStart,
    DateTime? plannedEnd,
    int? workBudget,
    int? materialsBudget,
  }) async {
    final p = await _ref.read(projectsRepositoryProvider).create(
          title: title,
          address: address,
          description: description,
          plannedStart: plannedStart,
          plannedEnd: plannedEnd,
          workBudget: workBudget,
          materialsBudget: materialsBudget,
        );
    _ref.read(activeProjectsProvider.notifier).prependCreated(p);
    return p;
  }

  Future<Project> copy(String projectId, {String? newTitle}) async {
    final p = await _ref
        .read(projectsRepositoryProvider)
        .copy(projectId, newTitle: newTitle);
    _ref.read(activeProjectsProvider.notifier).prependCreated(p);
    return p;
  }
}
