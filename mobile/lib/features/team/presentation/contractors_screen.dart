import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../data/team_repository.dart';

/// Корневая вкладка «Команда» в HomeShell. Показывает участников из всех
/// активных проектов пользователя — сгруппированных по проекту, с переходом
/// в TeamScreen конкретного проекта по тапу на заголовок группы.
class ContractorsScreen extends ConsumerWidget {
  const ContractorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myTeammatesProvider);
    return AppScaffold(
      title: 'Команда',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить команду',
          subtitle: e is TeamException
              ? '${e.failure.userMessage} (${e.apiError.code})'
              : e.toString(),
          onRetry: () => ref.invalidate(myTeammatesProvider),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return AppEmptyState(
              title: 'Команда формируется в проекте',
              subtitle:
                  'Создайте проект и добавьте участников, чтобы они появились '
                  'здесь.',
              icon: Icons.people_outline_rounded,
              actionLabel: 'К проектам',
              onAction: () => context.go(AppRoutes.projects),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myTeammatesProvider),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: groups.length,
              itemBuilder: (_, i) =>
                  _ProjectGroup(group: groups[i], allGroups: groups),
            ),
          );
        },
      ),
    );
  }
}

class _ProjectGroup extends StatelessWidget {
  const _ProjectGroup({required this.group, required this.allGroups});

  final TeammateGroup group;
  final List<TeammateGroup> allGroups;

  @override
  Widget build(BuildContext context) {
    final ownerAsMember = group.owner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.n50,
          child: InkWell(
            onTap: () =>
                context.push(AppRoutes.projectTeamWith(group.projectId)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.projectTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.n500,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.n400,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (ownerAsMember != null)
          _MemberRow(
            user: ownerAsMember,
            roleLabel: MembershipRole.customer.displayName,
            currentProjectId: group.projectId,
            currentProjectTitle: group.projectTitle,
            allGroups: allGroups,
          ),
        // Бекенд для legacy-проектов может содержать явную membership-строку
        // role=customer для ownerId. Не рендерим её повторно — owner уже
        // выведен через group.owner выше.
        for (final m in group.members)
          if (m.user != null &&
              !(m.userId == group.ownerId && m.role == MembershipRole.customer))
            _MemberRow(
              user: m.user!,
              roleLabel: m.role.displayName,
              currentProjectId: group.projectId,
              currentProjectTitle: group.projectTitle,
              allGroups: allGroups,
            ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.user,
    required this.roleLabel,
    required this.currentProjectId,
    required this.currentProjectTitle,
    required this.allGroups,
  });

  final ProjectMemberUser user;
  final String roleLabel;
  final String currentProjectId;
  final String currentProjectTitle;
  final List<TeammateGroup> allGroups;

  @override
  Widget build(BuildContext context) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    return Material(
      color: AppColors.n0,
      child: InkWell(
        onTap: () => _openCard(context, fullName),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x16,
            vertical: AppSpacing.x10,
          ),
          child: Row(
            children: [
              AppAvatar(
                seed: user.id,
                name: fullName,
                imageUrl: user.avatarUrl,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isEmpty ? user.phone : fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.n900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      roleLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.n500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.n400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCard(BuildContext context, String fullName) async {
    final commonProjects = <({String id, String title, String role})>[];
    for (final g in allGroups) {
      if (g.projectId == currentProjectId) continue;
      if (g.ownerId == user.id) {
        commonProjects.add((
          id: g.projectId,
          title: g.projectTitle,
          role: MembershipRole.customer.displayName,
        ));
        continue;
      }
      for (final m in g.members) {
        if (m.userId == user.id) {
          commonProjects.add((
            id: g.projectId,
            title: g.projectTitle,
            role: m.role.displayName,
          ));
          break;
        }
      }
    }

    await showMemberCardSheet(
      context,
      data: MemberCardData(
        userId: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        roleInCurrentProject: roleLabel,
        currentProjectTitle: currentProjectTitle,
        phone: user.phone,
        avatarUrl: user.avatarUrl,
        commonProjects: commonProjects,
      ),
      onOpenProject: (id) => context.go('/projects/$id'),
    );
  }
}
