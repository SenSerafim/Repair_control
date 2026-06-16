import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../projects/application/project_controller.dart';
import '../../projects/domain/membership.dart';
import '../../stages/application/stages_controller.dart';
import '../../stages/domain/stage.dart';
import '../application/team_controller.dart';
import '../data/team_repository.dart';
import '../domain/invitation.dart';
import 'generate_invite_code_sheet.dart';
import 'rep_rights_sheet.dart';

/// s-team — команда проекта.
// Ключ-сентинел для бакета «Без привязки к этапу» в _groupByStage.
const String _unassignedKey = '__unassigned__';

/// Группирует участников по `stageIds`. Один человек попадает во столько
/// групп, на сколько этапов он назначен. Участники с пустым `stageIds`
/// (заказчик, представитель, бригадир «на весь проект») идут в
/// бакет `_unassignedKey`. Группы для несуществующих stageId
/// (мастер на удалённом этапе) пропускаются.
Map<String, List<Membership>> _groupByStage(
  List<Membership> members,
  List<Stage> stages,
) {
  final stageSet = {for (final s in stages) s.id};
  final result = <String, List<Membership>>{
    _unassignedKey: <Membership>[],
    for (final s in stages) s.id: <Membership>[],
  };
  for (final m in members) {
    final ids = m.stageIds.where(stageSet.contains).toList();
    if (ids.isEmpty) {
      result[_unassignedKey]!.add(m);
    } else {
      for (final id in ids) {
        result[id]!.add(m);
      }
    }
  }
  return result;
}

class TeamScreen extends ConsumerWidget {
  const TeamScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teamControllerProvider(projectId));
    final canManage = ref.watch(
      canInProjectProvider((
        action: DomainAction.projectInviteMember,
        projectId: projectId,
      )),
    );

    return AppScaffold(
      showBack: true,
      title: 'Команда проекта',
      padding: EdgeInsets.zero,
      actions: [
        if (canManage) ...[
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            tooltip: 'Сгенерировать код приглашения',
            onPressed: () =>
                showGenerateInviteCodeSheet(context, ref, projectId: projectId),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'Добавить участника',
            onPressed: () =>
                context.push(AppRoutes.projectAddMemberWith(projectId)),
          ),
        ],
      ],
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить команду',
          subtitle: e.toString(),
          onRetry: () => ref.invalidate(teamControllerProvider(projectId)),
        ),
        data: (team) {
          if (team.isEmpty) {
            return AppEmptyState(
              title: 'Пока нет участников',
              subtitle: canManage
                  ? 'Пригласите представителя или бригадира — '
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
          // ТЗ NEWFIX §1.2: команда группируется по этапам, один человек
          // может появляться в нескольких группах. «Без привязки к этапу» —
          // для тех, чей stageIds пуст (заказчик / представитель / бригадир
          // на проекте целиком). Список этапов берём из stagesController —
          // даёт порядок и человекочитаемые названия.
          final stagesAsync = ref.watch(stagesControllerProvider(projectId));
          final stages = stagesAsync.value ?? const <Stage>[];
          // Серафим 08.06.2026: заказчик/представитель не должны видеть
          // мастеров в команде — мастеров приглашает бригадир, у заказчика
          // нет контекста по ним.
          final me = ref.watch(authControllerProvider).userId;
          final projectAsync = ref.watch(projectControllerProvider(projectId));
          final ownerId = projectAsync.maybeWhen(
            data: (p) => p.ownerId,
            orElse: () => null,
          );
          final myMembership = ref.watch(
            myMembershipInProjectProvider(projectId),
          );
          final viewerIsCustomerSide =
              (me != null && ownerId != null && me == ownerId) ||
              myMembership?.role == MembershipRole.customer ||
              myMembership?.role == MembershipRole.representative;
          final visibleMembers = viewerIsCustomerSide
              ? team.members
                    .where((m) => m.role != MembershipRole.master)
                    .toList()
              : team.members;
          final grouped = _groupByStage(visibleMembers, stages);
          final stageOrder = [
            for (final s in stages)
              if ((grouped[s.id] ?? const []).isNotEmpty) s,
          ];
          final unassigned = grouped[_unassignedKey] ?? const <Membership>[];
          return RefreshIndicator(
            onRefresh: () async {
              ref
                ..invalidate(teamControllerProvider(projectId))
                ..invalidate(stagesControllerProvider(projectId));
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.x16),
              children: [
                for (final stage in stageOrder) ...[
                  _SectionHeader(
                    label: 'Этап ${stage.orderIndex + 1} · ${stage.title}',
                  ),
                  const SizedBox(height: AppSpacing.x8),
                  ...grouped[stage.id]!.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.x10),
                      child: _MemberRow(projectId: projectId, member: m),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x12),
                ],
                if (unassigned.isNotEmpty) ...[
                  const _SectionHeader(label: 'Без привязки к этапу'),
                  const SizedBox(height: AppSpacing.x8),
                  ...unassigned.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.x10),
                      child: _MemberRow(projectId: projectId, member: m),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x12),
                ],
                if (team.invitations.isNotEmpty) ...[
                  const _SectionHeader(label: 'Приглашения'),
                  const SizedBox(height: AppSpacing.x8),
                  ...team.invitations.map(
                    (inv) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.x10),
                      child: _InvitationRow(
                        projectId: projectId,
                        invitation: inv,
                      ),
                    ),
                  ),
                ],
                // П2.16 — кнопка «Выйти из команды» для не-заказчика.
                _LeaveTeamSection(projectId: projectId, members: team.members),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// П2.16 — секция «Выйти из команды» внизу экрана команды. Видна только тем,
/// у кого есть активная membership в этом проекте, и кто не заказчик
/// (заказчик не может «выйти», у него только архивирование, см. backend).
class _LeaveTeamSection extends ConsumerWidget {
  const _LeaveTeamSection({required this.projectId, required this.members});

  final String projectId;
  final List<Membership> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.read(authControllerProvider).userId;
    if (me == null) return const SizedBox.shrink();
    final mine = members.where((m) => m.userId == me).toList();
    if (mine.isEmpty) return const SizedBox.shrink();
    final isOwnerOnly = mine.every((m) => m.role == MembershipRole.customer);
    if (isOwnerOnly) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: 'Выйти из команды',
            variant: AppButtonVariant.destructive,
            onPressed: () => _confirmLeave(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    // Сначала спрашиваем, что делать с инструментами этого пользователя
    // в проекте — П2.15. Если у пользователя нет инструментов, бэкенд
    // просто игнорирует toolsAction.
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из команды?'),
        content: const Text(
          'Вы потеряете доступ к проекту, чату и документам моментально.\n\n'
          'Если у вас есть инструменты в этом проекте, выберите, что с ними:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('transfer_to_owner'),
            child: const Text('Передать заказчику'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.redText),
            onPressed: () => Navigator.of(ctx).pop('take_away'),
            child: const Text('Забрать с собой'),
          ),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    try {
      await ref
          .read(teamRepositoryProvider)
          .leaveTeam(projectId: projectId, toolsAction: action);
      if (!context.mounted) return;
      AppToast.show(
        context,
        message: 'Вы вышли из команды',
        kind: AppToastKind.success,
      );
      // Возврат на главный список проектов; экран команды текущего проекта
      // больше не доступен.
      while (context.canPop()) {
        context.pop();
      }
    } on TeamException catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        message: e.failure.userMessage,
        kind: AppToastKind.error,
      );
    }
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
    final fullName = user == null
        ? ''
        : '${user.firstName} ${user.lastName}'.trim();
    // Серафим 08.06.2026: если ФИО пусто — показываем телефон вместо
    // безличного «Участник».
    final name = fullName.isNotEmpty
        ? fullName
        : _phoneLabel(user?.phone ?? '');
    final isRepresentative = member.role == MembershipRole.representative;
    final isCustomerRow = member.role == MembershipRole.customer;
    final me = ref.watch(authControllerProvider).userId;
    final isSelfRow = me != null && me == member.userId;
    final canManage = ref.watch(
      canInProjectProvider((
        action: DomainAction.projectInviteMember,
        projectId: projectId,
      )),
    );
    // Кнопка «Удалить» не имеет смысла:
    //   • на самом себе — для self-leave есть отдельная секция «Выйти из команды» внизу.
    //   • на строке заказчика — owner-membership не удаляется (бэкенд вернёт 400).
    final canRemoveThisMember = canManage && !isSelfRow && !isCustomerRow;
    final roleTone = _toneFor(member.role);
    return InkWell(
      borderRadius: AppRadius.card,
      // ТЗ NEWFIX §1.2: тап по строке = переход в полноценный профиль
      // сотрудника. Меню с действиями уехало в long-press, чтобы
      // основной жест работал по §3.3.
      onTap: () => context.push('/projects/$projectId/team/${member.userId}'),
      onLongPress: () => _showCard(
        context,
        ref,
        name: name,
        canManage: canManage,
        canRemove: canRemoveThisMember,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.n0,
          border: Border.all(color: AppColors.n200),
          borderRadius: AppRadius.card,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0D1229),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
            BoxShadow(
              color: Color(0x1F4F6EF7),
              offset: Offset(0, 10),
              blurRadius: 24,
              spreadRadius: -10,
            ),
          ],
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x290D1229),
                    offset: Offset(0, 4),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                  color: AppColors.n0,
                  shape: BoxShape.circle,
                ),
                child: AppAvatar(
                  seed: member.userId,
                  name: name,
                  imageUrl: user?.avatarUrl,
                  size: 37,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? '—' : name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.n900,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    () {
                      final spec = MembershipSpecialization.of(member.id);
                      if (member.role == MembershipRole.master &&
                          spec != null) {
                        return '${member.role.displayName} · $spec';
                      }
                      return member.role.displayName;
                    }(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _roleColor(roleTone),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (canManage && (isRepresentative || canRemoveThisMember))
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
                  if (canRemoveThisMember)
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
      ),
    );
  }

  /// П2.1 — карточка участника команды (общий компонент с чатом, П1.4).
  Future<void> _showCard(
    BuildContext context,
    WidgetRef ref, {
    required String name,
    required bool canManage,
    required bool canRemove,
  }) async {
    // QA-баг #6 «не открывается карточка участника»: до этого фикса
    // _showCard молча выходил, если бэк по какой-то причине не вернул
    // вложенный user (deleted-аккаунт, частичный ответ, кеш race).
    // Теперь падаем в графу best-effort: используем member.userId и то,
    // что есть в name/role, а недостающее показываем как «—».
    final user = member.user;
    final userIdForCommon = user?.id ?? member.userId;
    final commonProjects = await _loadCommonProjects(ref, userIdForCommon);
    if (!context.mounted) return;
    final parts = name.trim().split(RegExp(r'\s+'));
    final fallbackFirstName =
        user?.firstName ??
        (parts.isNotEmpty && parts.first.isNotEmpty
            ? parts.first
            : _phoneLabel(user?.phone ?? ''));
    final fallbackLastName =
        user?.lastName ?? (parts.length > 1 ? parts.sublist(1).join(' ') : '');
    final isRepresentativeMember = member.role == MembershipRole.representative;
    await showMemberCardSheet(
      context,
      data: MemberCardData(
        userId: userIdForCommon,
        firstName: fallbackFirstName,
        lastName: fallbackLastName,
        roleInCurrentProject: member.role.displayName,
        currentProjectTitle:
            '', // не показываем — экран уже в контексте проекта
        phone: user?.phone ?? '',
        avatarUrl: user?.avatarUrl,
        commonProjects: commonProjects,
      ),
      onOpenProject: (id) => context.go('/projects/$id'),
      // ROLES §11.8 — карточка представителя ведёт к sheet'у с 13 чекбоксами
      // DomainAction. Доступно тем, у кого есть управленческие права в проекте
      // (заказчик/привилегированный представитель).
      onOpenRepRights: (isRepresentativeMember && canManage)
          ? () => showRepRightsSheet(
              context,
              ref,
              projectId: projectId,
              member: member,
            )
          : null,
      onRemoveFromTeam: canRemove
          ? () async {
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
          : null,
    );
  }

  /// Собирает список общих проектов с этим участником (кроме текущего).
  /// Источник — `myTeammatesProvider` (GET /api/me/teammates), кешируется
  /// в Riverpod, так что повторный вызов недорогой.
  Future<List<({String id, String title, String role})>> _loadCommonProjects(
    WidgetRef ref,
    String otherUserId,
  ) async {
    try {
      final groups = await ref.read(myTeammatesProvider.future);
      final out = <({String id, String title, String role})>[];
      for (final g in groups) {
        if (g.projectId == projectId) continue;
        if (g.ownerId == otherUserId) {
          out.add((id: g.projectId, title: g.projectTitle, role: 'Заказчик'));
          continue;
        }
        final m = g.members.where((mm) => mm.userId == otherUserId).firstOrNull;
        if (m != null) {
          out.add((
            id: g.projectId,
            title: g.projectTitle,
            role: m.role.displayName,
          ));
        }
      }
      return out;
    } on Object {
      return const [];
    }
  }
}

AppRoleBadgeTone _toneFor(MembershipRole role) {
  switch (role) {
    case MembershipRole.customer:
      return AppRoleBadgeTone.customer;
    case MembershipRole.foreman:
      return AppRoleBadgeTone.foreman;
    case MembershipRole.master:
      return AppRoleBadgeTone.worker;
    case MembershipRole.representative:
      return AppRoleBadgeTone.representative;
  }
}

Color _roleColor(AppRoleBadgeTone tone) {
  switch (tone) {
    case AppRoleBadgeTone.customer:
      return AppColors.brand;
    case AppRoleBadgeTone.foreman:
      return AppColors.greenDark;
    case AppRoleBadgeTone.worker:
      return AppColors.purple;
    case AppRoleBadgeTone.representative:
      return AppColors.yellowText;
    case AppRoleBadgeTone.neutral:
      return AppColors.n500;
  }
}

class _InvitationRow extends ConsumerWidget {
  const _InvitationRow({required this.projectId, required this.invitation});

  final String projectId;
  final Invitation invitation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = invitation.status == InvitationStatus.pending;
    final canManage = ref.watch(
      canInProjectProvider((
        action: DomainAction.projectInviteMember,
        projectId: projectId,
      )),
    );
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
          subtitle:
              '«$name» потеряет доступ к проекту. '
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

// Серафим 08.06.2026: вместо безличного «Участник» когда ФИО пусто —
// показываем последние 4 цифры телефона. Если и телефона нет — fallback.
String _phoneLabel(String phone) {
  final p = phone.trim();
  if (p.isEmpty) return "Участник";
  if (p.length <= 4) return p;
  return "+•• ${p.substring(p.length - 4)}";
}
