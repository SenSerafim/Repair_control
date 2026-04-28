import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../application/team_controller.dart';
import '../domain/invitation.dart';
import 'generate_invite_code_sheet.dart';
import 'rep_rights_sheet.dart';

/// s-team — команда проекта.
class TeamScreen extends ConsumerWidget {
  const TeamScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teamControllerProvider(projectId));
    final canManage = ref.watch(canInProjectProvider(
      (action: DomainAction.projectInviteMember, projectId: projectId),
    ));

    return AppScaffold(
      showBack: true,
      title: 'Команда проекта',
      padding: EdgeInsets.zero,
      actions: [
        if (canManage) ...[
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            tooltip: 'Сгенерировать код приглашения',
            onPressed: () => showGenerateInviteCodeSheet(
              context,
              ref,
              projectId: projectId,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'Добавить участника',
            onPressed: () => context.push(
              AppRoutes.projectAddMemberWith(projectId),
            ),
          ),
        ],
      ],
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить команду',
          subtitle: e.toString(),
          onRetry: () =>
              ref.invalidate(teamControllerProvider(projectId)),
        ),
        data: (team) {
          if (team.isEmpty) {
            return AppEmptyState(
              title: 'Пока нет участников',
              subtitle: canManage
                  ? 'Пригласите представителя, бригадира или мастера — '
                      'они получат доступ к проекту сразу после входа.\n\n'
                      'Самый быстрый способ — сгенерировать 6-значный код '
                      'и отправить его получателю в любой мессенджер.'
                  : 'Заказчик ещё не пригласил участников.',
              icon: Icons.people_outline_rounded,
              actionLabel: canManage ? 'Сгенерировать код' : null,
              onAction: canManage
                  ? () => showGenerateInviteCodeSheet(
                      context,
                      ref,
                      projectId: projectId,
                    )
                  : null,
            );
          }
          final grouped = <MembershipRole, List<Membership>>{
            for (final role in MembershipRole.values)
              role: team.members.where((m) => m.role == role).toList(),
          };
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(teamControllerProvider(projectId)),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.x16),
              children: [
                for (final role in MembershipRole.values)
                  if (grouped[role]!.isNotEmpty) ...[
                    _SectionHeader(label: role.displayName),
                    const SizedBox(height: AppSpacing.x8),
                    ...grouped[role]!.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.x10,
                        ),
                        child: _MemberRow(
                          projectId: projectId,
                          member: m,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x12),
                  ],
                if (team.invitations.isNotEmpty) ...[
                  const _SectionHeader(label: 'Приглашения'),
                  const SizedBox(height: AppSpacing.x8),
                  ...team.invitations.map(
                    (inv) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.x10),
                      child: _InvitationRow(
                        projectId: projectId,
                        invitation: inv,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.x4),
      child: Text(label, style: AppTextStyles.micro),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({required this.projectId, required this.member});

  final String projectId;
  final Membership member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = member.user;
    final name = user == null
        ? 'Участник'
        : '${user.firstName} ${user.lastName}'.trim();
    final isRepresentative = member.role == MembershipRole.representative;
    final canManage = ref.watch(canInProjectProvider(
      (action: DomainAction.projectInviteMember, projectId: projectId),
    ));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Row(
        children: [
          AppAvatar(
            seed: member.userId,
            name: name,
            imageUrl: user?.avatarUrl,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? '—' : name,
                  style: AppTextStyles.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user?.phone != null)
                  Text(user!.phone, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (canManage)
            PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'rights' && isRepresentative) {
                await showRepRightsSheet(
                  context,
                  ref,
                  projectId: projectId,
                  member: member,
                );
              } else if (v == 'remove') {
                final confirmed = await showAppBottomSheet<bool>(
                  context: context,
                  child: _RemoveConfirm(name: name),
                );
                if ((confirmed ?? false) && context.mounted) {
                  final failure = await ref
                      .read(teamControllerProvider(projectId).notifier)
                      .removeMember(member.id);
                  if (!context.mounted) return;
                  AppToast.show(
                    context,
                    message: failure == null
                        ? 'Участник удалён'
                        : failure.userMessage,
                    kind: failure == null
                        ? AppToastKind.success
                        : AppToastKind.error,
                  );
                }
              }
            },
            itemBuilder: (_) => [
              if (isRepresentative)
                const PopupMenuItem(
                  value: 'rights',
                  child: Text('Настроить права'),
                ),
              const PopupMenuItem(
                value: 'remove',
                child: Text(
                  'Удалить из команды',
                  style: TextStyle(color: AppColors.redDot),
                ),
              ),
            ],
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.n400,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitationRow extends ConsumerWidget {
  const _InvitationRow({
    required this.projectId,
    required this.invitation,
  });

  final String projectId;
  final Invitation invitation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = invitation.status == InvitationStatus.pending;
    final canManage = ref.watch(canInProjectProvider(
      (action: DomainAction.projectInviteMember, projectId: projectId),
    ));
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mark_email_unread_outlined,
            color: AppColors.brand,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invitation.phone, style: AppTextStyles.subtitle),
                const SizedBox(height: 2),
                Text(
                  '${invitation.role.displayName} · ${invitation.status.displayName}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (pending && canManage)
            TextButton(
              onPressed: () async {
                final failure = await ref
                    .read(teamControllerProvider(projectId).notifier)
                    .cancelInvitation(invitation.id);
                if (!context.mounted) return;
                AppToast.show(
                  context,
                  message: failure == null
                      ? 'Приглашение отменено'
                      : failure.userMessage,
                );
              },
              child: const Text('Отменить'),
            ),
        ],
      ),
    );
  }
}

class _RemoveConfirm extends StatelessWidget {
  const _RemoveConfirm({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBottomSheetHeader(
          title: 'Удалить участника?',
          subtitle: '«$name» потеряет доступ к проекту. '
              'История шагов и сообщений сохранится.',
        ),
        AppButton(
          label: 'Да, удалить',
          variant: AppButtonVariant.destructive,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: AppSpacing.x8),
        AppButton(
          label: 'Отмена',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
