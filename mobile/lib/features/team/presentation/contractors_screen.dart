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
              itemBuilder: (_, i) => _ProjectGroup(group: groups[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ProjectGroup extends StatelessWidget {
  const _ProjectGroup({required this.group});

  final TeammateGroup group;

  @override
  Widget build(BuildContext context) {
    final ownerAsMember = group.owner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.n50,
          child: InkWell(
            onTap: () => context.push(
              AppRoutes.projectTeamWith(group.projectId),
            ),
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
          ),
        for (final m in group.members)
          if (m.user != null)
            _MemberRow(
              user: m.user!,
              roleLabel: m.role.displayName,
            ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.user, required this.roleLabel});

  final ProjectMemberUser user;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    return Material(
      color: AppColors.n0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x16,
          vertical: AppSpacing.x10,
        ),
        child: Row(
          children: [
            AppAvatar(seed: user.id, name: fullName, size: 40),
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
          ],
        ),
      ),
    );
  }
}
