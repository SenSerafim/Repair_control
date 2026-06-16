import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/access/representative_rights.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../data/team_repository.dart';
import '../domain/representative_rights_l10n.dart';

/// s-rep-rights — экран настройки прав представителя при добавлении в проект.
///
/// Все 10 флагов `RepresentativeRights` (см.
/// `backend/libs/rbac/src/rbac.types.ts`) разнесены в две секции:
///   • «Просмотр» — права без побочных эффектов (бюджет).
///   • «Действия» — write-операции (создание этапов, согласования, команда,
///     финансы, материалы и инструмент).
/// Ключи отправляемого JSON — это `RepresentativeRight.jsonKey`, которые
/// принимает backend `sanitizeRepresentativeRights`.
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
  late final Map<RepresentativeRight, bool> _rights = {
    for (final r in RepresentativeRight.values) r: false,
  };

  bool _busy = false;

  // Какие права попадают в секцию «Просмотр». Остальные — в «Действия».
  static const _viewRights = <RepresentativeRight>{
    RepresentativeRight.canSeeBudget,
  };

  Map<String, bool> _toPermissionsJson() => <String, bool>{
    for (final entry in _rights.entries) entry.key.jsonKey: entry.value,
  };

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(teamRepositoryProvider)
          .addMember(
            projectId: widget.projectId,
            userId: widget.user.id,
            role: MembershipRole.representative,
            permissions: _toPermissionsJson(),
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
    final fullName = '${widget.user.firstName} ${widget.user.lastName}'.trim();

    final viewRights = <RepresentativeRight>[];
    final actionRights = <RepresentativeRight>[];
    for (final r in RepresentativeRight.values) {
      (_viewRights.contains(r) ? viewRights : actionRights).add(r);
    }

    return AppScaffold(
      showBack: true,
      title: 'Права представителя',
      backgroundColor: AppColors.n50,
      padding: EdgeInsets.zero,
      body: ListView(
        children: [
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
          const _SectionLabel(text: 'Просмотр'),
          _RightsGroup(
            children: [
              const _ReadOnlyRow(title: 'Этапы и шаги', sub: 'Всегда включено'),
              for (final right in viewRights)
                _RightToggleRow(
                  right: right,
                  value: _rights[right] ?? false,
                  onChanged: (v) => setState(() => _rights[right] = v),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x12),
          const _SectionLabel(text: 'Действия'),
          _RightsGroup(
            children: [
              for (final right in actionRights)
                _RightToggleRow(
                  right: right,
                  value: _rights[right] ?? false,
                  onChanged: (v) => setState(() => _rights[right] = v),
                ),
            ],
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

class _RightsGroup extends StatelessWidget {
  const _RightsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      child: AppMenuGroup(children: children),
    );
  }
}

class _RightToggleRow extends StatelessWidget {
  const _RightToggleRow({
    required this.right,
    required this.value,
    required this.onChanged,
  });

  final RepresentativeRight right;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = kRepresentativeRightLabels[right];
    return AppMenuRow(
      label: label?.title ?? right.jsonKey,
      sub: label?.description,
      trailing: _Toggle(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.title, required this.sub});

  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return AppMenuRow(
      label: title,
      sub: sub,
      disabled: true,
      trailing: const _Toggle(value: true, disabled: true),
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
  const _Toggle({required this.value, this.onChanged, this.disabled = false});

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
