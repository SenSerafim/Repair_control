import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../data/team_repository.dart';

/// s-rep-rights — экран настройки прав представителя в проекте.
///
/// Содержит карточку представителя сверху и две секции тоглов:
/// «Просмотр» (always-on Этапы и шаги, плюс Бюджет проекта/этапов и Лента
/// финансов) и «Действия» (Добавление этапов, Назначение подрядчиков,
/// Принятие/отклонение работ, Добавление подшагов).
class ProjectRepRightsScreen extends ConsumerStatefulWidget {
  const ProjectRepRightsScreen({
    required this.projectId,
    required this.user,
    super.key,
  });

  final String projectId;
  final ProjectMemberUser user;

  @override
  ConsumerState<ProjectRepRightsScreen> createState() =>
      _ProjectRepRightsScreenState();
}

class _ProjectRepRightsScreenState
    extends ConsumerState<ProjectRepRightsScreen> {
  // Просмотр.
  bool _viewBudgetProject = true;
  bool _viewBudgetStages = true;
  bool _viewFinanceFeed = false;
  // Действия.
  bool _addStages = false;
  bool _assignContractors = false;
  bool _approveWorks = true;
  bool _addSubsteps = true;

  bool _busy = false;

  Map<String, bool> _permissions() => {
        'canSeeProjectBudget': _viewBudgetProject,
        'canSeeStageBudget': _viewBudgetStages,
        'canSeeFinanceFeed': _viewFinanceFeed,
        'canAddStages': _addStages,
        'canAssignContractors': _assignContractors,
        'canApproveWorks': _approveWorks,
        'canAddSubsteps': _addSubsteps,
      };

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      // Сначала добавляем как representative с правами.
      await ref.read(teamRepositoryProvider).addMember(
            projectId: widget.projectId,
            userId: widget.user.id,
            role: MembershipRole.representative,
            permissions: _permissions(),
          );
      if (!mounted) return;
      AppToast.show(
        context,
        message: '✓ Права сохранены',
        kind: AppToastKind.success,
      );
      context.go(AppRoutes.projectTeamWith(widget.projectId));
    } on TeamException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.show(
        context,
        message: e.failure.userMessage,
        kind: AppToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName =
        '${widget.user.firstName} ${widget.user.lastName}'.trim();

    return AppScaffold(
      showBack: true,
      title: 'Права представителя',
      backgroundColor: AppColors.n50,
      padding: EdgeInsets.zero,
      body: ListView(
        children: [
          // Карточка представителя.
          Padding(
            padding: const EdgeInsets.all(AppSpacing.x16),
            child: Row(
              children: [
                AppAvatar(
                  seed: widget.user.id,
                  name: fullName,
                  size: 48,
                  palette: AvatarPalette.purple,
                ),
                const SizedBox(width: AppSpacing.x14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.n800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Представитель заказчика',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.n400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Секция «Просмотр».
          _SectionLabel(text: 'Просмотр'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
            child: AppMenuGroup(
              children: [
                AppMenuRow(
                  label: 'Этапы и шаги',
                  sub: 'Всегда включено',
                  disabled: true,
                  trailing: const _Toggle(value: true, disabled: true),
                ),
                AppMenuRow(
                  label: 'Бюджет проекта',
                  trailing: _Toggle(
                    value: _viewBudgetProject,
                    onChanged: (v) =>
                        setState(() => _viewBudgetProject = v),
                  ),
                  onTap: () => setState(
                    () => _viewBudgetProject = !_viewBudgetProject,
                  ),
                ),
                AppMenuRow(
                  label: 'Бюджет этапов',
                  trailing: _Toggle(
                    value: _viewBudgetStages,
                    onChanged: (v) =>
                        setState(() => _viewBudgetStages = v),
                  ),
                  onTap: () => setState(
                    () => _viewBudgetStages = !_viewBudgetStages,
                  ),
                ),
                AppMenuRow(
                  label: 'Лента событий (финансы)',
                  trailing: _Toggle(
                    value: _viewFinanceFeed,
                    onChanged: (v) =>
                        setState(() => _viewFinanceFeed = v),
                  ),
                  onTap: () => setState(
                    () => _viewFinanceFeed = !_viewFinanceFeed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          // Секция «Действия».
          _SectionLabel(text: 'Действия'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
            child: AppMenuGroup(
              children: [
                AppMenuRow(
                  label: 'Добавление этапов',
                  trailing: _Toggle(
                    value: _addStages,
                    onChanged: (v) => setState(() => _addStages = v),
                  ),
                  onTap: () => setState(() => _addStages = !_addStages),
                ),
                AppMenuRow(
                  label: 'Назначение подрядчиков',
                  trailing: _Toggle(
                    value: _assignContractors,
                    onChanged: (v) =>
                        setState(() => _assignContractors = v),
                  ),
                  onTap: () => setState(
                    () => _assignContractors = !_assignContractors,
                  ),
                ),
                AppMenuRow(
                  label: 'Принятие / отклонение работ',
                  trailing: _Toggle(
                    value: _approveWorks,
                    onChanged: (v) =>
                        setState(() => _approveWorks = v),
                  ),
                  onTap: () =>
                      setState(() => _approveWorks = !_approveWorks),
                ),
                AppMenuRow(
                  label: 'Добавление подшагов',
                  trailing: _Toggle(
                    value: _addSubsteps,
                    onChanged: (v) => setState(() => _addSubsteps = v),
                  ),
                  onTap: () =>
                      setState(() => _addSubsteps = !_addSubsteps),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.x16),
            child: AppButton(
              label: 'Сохранить права',
              isLoading: _busy,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x20,
        AppSpacing.x4,
        AppSpacing.x20,
        AppSpacing.x8,
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.n400,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.value,
    this.onChanged,
    this.disabled = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Switch.adaptive(
        value: value,
        onChanged: disabled ? null : onChanged,
        activeColor: AppColors.brand,
      ),
    );
  }
}
