import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../../team/data/team_repository.dart';
import '../application/team_visibility.dart';

/// NEWFIX-2 §3 — Агрегированный экран «Команда» внутри Чатов.
/// Вход: Чаты → шапка → иконка «Команда». Сверху — табы-фильтры по проектам;
/// ниже — плоский список сотрудников; тап = переход в полный профиль (E4).
class TeamAggregateScreen extends ConsumerStatefulWidget {
  const TeamAggregateScreen({super.key});

  @override
  ConsumerState<TeamAggregateScreen> createState() =>
      _TeamAggregateScreenState();
}

class _TeamAggregateScreenState extends ConsumerState<TeamAggregateScreen> {
  String? _projectFilter; // null = все проекты

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myTeammatesProvider);
    return AppScaffold(
      showBack: true,
      title: 'Команда',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить команду',
          subtitle: e.toString(),
          onRetry: () => ref.invalidate(myTeammatesProvider),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return const AppEmptyState(
              title: 'Команды пока нет',
              subtitle:
                  'Когда вы добавите участников в проекты — они появятся здесь.',
              icon: Icons.group_outlined,
            );
          }
          // Если фильтр стал невалидным (проект пропал из ответа) — сбрасываем.
          if (_projectFilter != null &&
              !groups.any((g) => g.projectId == _projectFilter)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _projectFilter = null);
            });
          }
          final filtered = _projectFilter == null
              ? groups
              : groups.where((g) => g.projectId == _projectFilter).toList();
          // NEWFIX-2 §6.1 — клиентская оборона: заказчик не должен видеть
          // мастеров. Сервер уже фильтрует (`/api/me/teammates`), но клиент
          // дублирует проверку, чтобы приватность держалась даже если бек
          // когда-нибудь вернёт «лишних» (defense-in-depth).
          final viewerRole = ref.watch(activeRoleProvider);
          // Плоский dedup по userId — один и тот же сотрудник может быть в
          // нескольких проектах, в общем списке показываем одной строкой.
          final byUserId = <String, _Row>{};
          for (final g in filtered) {
            final visibleMembers = filterMembershipsForRole(
              g.members,
              viewerRole,
            );
            for (final m in visibleMembers) {
              final id = m.userId;
              final existing = byUserId[id];
              if (existing == null) {
                byUserId[id] = _Row(
                  membership: m,
                  projectTitles: [g.projectTitle],
                );
              } else {
                existing.projectTitles.add(g.projectTitle);
              }
            }
          }
          final flat = byUserId.values.toList();
          return Column(
            children: [
              _ProjectTabs(
                groups: groups,
                selected: _projectFilter,
                onChanged: (id) => setState(() => _projectFilter = id),
              ),
              Expanded(
                child: flat.isEmpty
                    ? const AppEmptyState(
                        title: 'В этом проекте никого нет',
                        icon: Icons.group_outlined,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.x16,
                          AppSpacing.x8,
                          AppSpacing.x16,
                          AppSpacing.x24,
                        ),
                        itemCount: flat.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.x10),
                        itemBuilder: (_, i) => _MemberRow(
                          row: flat[i],
                          onTap: () => context.push(
                            '/team/${flat[i].membership.userId}',
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Row {
  _Row({required this.membership, required this.projectTitles});
  final Membership membership;
  final List<String> projectTitles;
}

class _ProjectTabs extends StatelessWidget {
  const _ProjectTabs({
    required this.groups,
    required this.selected,
    required this.onChanged,
  });

  final List<TeammateGroup> groups;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppFilterPillBar(
      chips: [
        const AppFilterPillSpec(id: '__all__', label: 'Все'),
        for (final g in groups)
          AppFilterPillSpec(id: g.projectId, label: g.projectTitle),
      ],
      activeId: selected ?? '__all__',
      onSelect: (id) => onChanged(id == '__all__' ? null : id),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.row, required this.onTap});
  final _Row row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final user = row.membership.user;
    final name = user == null
        ? row.membership.userId
        : '${user.firstName} ${user.lastName}'.trim();
    final projects = row.projectTitles.toSet().toList().join(' · ');
    return Material(
      color: AppColors.n0,
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.n200),
            borderRadius: AppRadius.card,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.brandLight,
                child: Text(
                  _initials(user?.firstName, user?.lastName),
                  style: const TextStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? row.membership.userId : name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.n800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row.membership.role.displayName,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.n500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (projects.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        projects,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.n400,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 18,
                color: AppColors.n300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String? f, String? l) {
    String pick(String? s) =>
        (s == null || s.isEmpty) ? '' : s.trim().substring(0, 1).toUpperCase();
    final out = '${pick(f)}${pick(l)}';
    return out.isEmpty ? '?' : out;
  }
}
