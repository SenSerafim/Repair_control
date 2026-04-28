import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/access/system_role.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_failure.dart';
import '../../projects/application/projects_list_controller.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

/// Провайдер профиля. Автоматически загружает /me для authenticated users
/// и держит кеш.
final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    ref.listen<AuthStatus>(
      authControllerProvider.select((s) => s.status),
      (prev, next) {
        if (next == AuthStatus.unauthenticated) {
          state = AsyncError(
            'unauthenticated',
            StackTrace.current,
          );
        }
      },
    );
    final repo = ref.read(profileRepositoryProvider);
    return repo.getMe();
  }

  Future<AuthFailure?> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? avatarUrl,
    String? language,
  }) async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      final updated = await repo.updateMe(
        firstName: firstName,
        lastName: lastName,
        email: email,
        avatarUrl: avatarUrl,
        language: language,
      );
      state = AsyncData(updated);
      return null;
    } on ProfileException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> setActiveRole(SystemRole role) async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.setActiveRole(role);
      await ref
          .read(authControllerProvider.notifier)
          .setActiveRole(role);
      final current = state.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            activeRole: role,
            roles: current.roles
                .map((r) => r.copyWith(isActive: r.role == role))
                .toList(),
          ),
        );
      }
      // Каждая роль — изолированный «аккаунт»: проекты/архив свои.
      // После переключения — инвалидируем верхнеуровневые провайдеры
      // данных, чтобы экраны перечитали с бэка под новую активную роль.
      ref
        ..invalidate(activeProjectsProvider)
        ..invalidate(archivedProjectsProvider);
      return null;
    } on ProfileException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> addRole(SystemRole role) async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      final roles = await repo.addRole(role);
      final current = state.value;
      if (current != null) {
        state = AsyncData(current.copyWith(roles: roles));
      }
      return null;
    } on ProfileException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> removeRole(SystemRole role) async {
    try {
      final repo = ref.read(profileRepositoryProvider);
      final roles = await repo.removeRole(role);
      final current = state.value;
      if (current != null) {
        state = AsyncData(current.copyWith(roles: roles));
      }
      return null;
    } on ProfileException catch (e) {
      return e.failure;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(profileRepositoryProvider);
      state = AsyncData(await repo.getMe());
    } on ProfileException catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
