import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/access/access_guard.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../auth/domain/auth_failure.dart';
import '../data/projects_repository.dart';
import '../domain/project.dart';

/// Фильтр списка проектов.
enum ProjectsFilter {
  all,
  ok,
  approval,
  late_,
  delay;

  String get label => switch (this) {
        ProjectsFilter.all => 'Все',
        ProjectsFilter.ok => 'По графику',
        ProjectsFilter.approval => 'Согласования',
        ProjectsFilter.late_ => 'Просрочен',
        ProjectsFilter.delay => 'Отставание',
      };

  bool matches(Project p) => switch (this) {
        ProjectsFilter.all => true,
        ProjectsFilter.ok => p.semaphore == Semaphore.green,
        ProjectsFilter.approval => p.semaphore == Semaphore.blue,
        ProjectsFilter.late_ => p.semaphore == Semaphore.red,
        ProjectsFilter.delay => p.semaphore == Semaphore.yellow,
      };
}

final projectsFilterProvider =
    StateProvider<ProjectsFilter>((ref) => ProjectsFilter.all);

final projectsSearchQueryProvider = StateProvider<String>((ref) => '');

/// Активные проекты.
final activeProjectsProvider =
    AsyncNotifierProvider<ActiveProjectsController, List<Project>>(
  ActiveProjectsController.new,
);

class ActiveProjectsController extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    // Подписка на activeRole — при переключении ролей список перестраивается
    // автоматически (каждая роль = отдельный «аккаунт» по UX-требованию).
    final role = ref.watch(activeRoleProvider);
    return ref
        .read(projectsRepositoryProvider)
        .list(status: ProjectStatus.active, role: role?.name);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final role = ref.read(activeRoleProvider);
      state = AsyncData(
        await ref
            .read(projectsRepositoryProvider)
            .list(status: ProjectStatus.active, role: role?.name),
      );
    } on ProjectsException catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<AuthFailure?> archiveById(String projectId) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((p) => p.id != projectId).toList());
    try {
      await ref.read(projectsRepositoryProvider).archive(projectId);
      ref.invalidate(archivedProjectsProvider);
      return null;
    } on ProjectsException catch (e) {
      state = AsyncData(current); // откат
      return e.failure;
    }
  }

  void prependCreated(Project p) {
    final current = state.value ?? [];
    state = AsyncData([p, ...current]);
  }

  void replaceUpdated(Project p) {
    final current = state.value ?? [];
    state = AsyncData(
      current.map((x) => x.id == p.id ? p : x).toList(),
    );
  }
}

/// Архивные проекты.
final archivedProjectsProvider =
    AsyncNotifierProvider<ArchivedProjectsController, List<Project>>(
  ArchivedProjectsController.new,
);

class ArchivedProjectsController extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    final role = ref.watch(activeRoleProvider);
    return ref
        .read(projectsRepositoryProvider)
        .list(status: ProjectStatus.archived, role: role?.name);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final role = ref.read(activeRoleProvider);
      state = AsyncData(
        await ref
            .read(projectsRepositoryProvider)
            .list(status: ProjectStatus.archived, role: role?.name),
      );
    } on ProjectsException catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<AuthFailure?> restoreById(String projectId) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((p) => p.id != projectId).toList());
    try {
      await ref.read(projectsRepositoryProvider).restore(projectId);
      ref.invalidate(activeProjectsProvider);
      return null;
    } on ProjectsException catch (e) {
      state = AsyncData(current);
      return e.failure;
    }
  }
}

/// Отфильтрованный + поиск-отлайн список активных. Читает активные +
/// projectsFilterProvider + projectsSearchQueryProvider.
final filteredActiveProjectsProvider = Provider<AsyncValue<List<Project>>>(
  (ref) {
    final async = ref.watch(activeProjectsProvider);
    final filter = ref.watch(projectsFilterProvider);
    final query = ref.watch(projectsSearchQueryProvider).toLowerCase().trim();

    return async.whenData((items) {
      return items.where((p) {
        if (!filter.matches(p)) return false;
        if (query.isEmpty) return true;
        return p.title.toLowerCase().contains(query) ||
            (p.address?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  },
);
