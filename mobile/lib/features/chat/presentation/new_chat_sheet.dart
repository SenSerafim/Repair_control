import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../../team/application/team_controller.dart';
import '../data/chats_repository.dart';

/// f-chat-new / f-chat-group-select — выбор типа и собеседников.
/// Сначала тип: «Личный» / «Группа». Для group — выбор участников.
Future<void> showNewChatSheet(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    child: _NewChatBody(projectId: projectId),
  );
}

class _NewChatBody extends ConsumerStatefulWidget {
  const _NewChatBody({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_NewChatBody> createState() => _NewChatBodyState();
}

class _NewChatBodyState extends ConsumerState<_NewChatBody> {
  _Step _step = _Step.pickType;
  final Set<String> _selected = {};
  final _title = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _Step.pickType => _TypePicker(
          onPersonal: () => setState(() => _step = _Step.personal),
          onGroup: () => setState(() => _step = _Step.group),
        ),
      _Step.personal => _PersonalPicker(
          projectId: widget.projectId,
          onPick: _createPersonal,
          error: _error,
          busy: _submitting,
        ),
      _Step.group => _GroupPicker(
          projectId: widget.projectId,
          selected: _selected,
          title: _title,
          onToggle: (id) => setState(() {
            if (!_selected.remove(id)) _selected.add(id);
          }),
          onCreate: _createGroup,
          error: _error,
          busy: _submitting,
        ),
    };
  }

  Future<void> _createPersonal(String userId) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final chat = await ref.read(chatsRepositoryProvider).createPersonal(
            projectId: widget.projectId,
            withUserId: userId,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      unawaited(context.push(AppRoutes.chatDetailWith(chat.id)));
    } on ChatsException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.failure.userMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _createGroup() async {
    if (_selected.isEmpty) {
      setState(() => _error = 'Выберите хотя бы одного участника');
      return;
    }
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Введите название группы');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final chat = await ref.read(chatsRepositoryProvider).createGroup(
            projectId: widget.projectId,
            title: title,
            participantUserIds: _selected.toList(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      unawaited(context.push(AppRoutes.chatDetailWith(chat.id)));
    } on ChatsException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.failure.userMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

enum _Step { pickType, personal, group }

class _TypePicker extends StatelessWidget {
  const _TypePicker({required this.onPersonal, required this.onGroup});

  final VoidCallback onPersonal;
  final VoidCallback onGroup;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Новый чат',
          subtitle: 'Какой чат хотите создать?',
        ),
        _TypeTile(
          icon: Icons.person_outline,
          iconBg: AppColors.brandLight,
          iconColor: AppColors.brand,
          title: 'Личный чат',
          subtitle: 'С одним участником проекта',
          onTap: onPersonal,
        ),
        const SizedBox(height: AppSpacing.x8),
        _TypeTile(
          icon: Icons.groups_outlined,
          iconBg: AppColors.greenLight,
          iconColor: AppColors.greenDark,
          title: 'Группа',
          subtitle: 'Несколько участников + название',
          onTap: onGroup,
        ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.n200),
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.subtitle),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.n400),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.n300),
          ],
        ),
      ),
    );
  }
}

class _PersonalPicker extends ConsumerWidget {
  const _PersonalPicker({
    required this.projectId,
    required this.onPick,
    required this.error,
    required this.busy,
  });

  final String projectId;
  final ValueChanged<String> onPick;
  final String? error;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamControllerProvider(projectId));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Личный чат',
          subtitle: 'Выберите участника проекта',
        ),
        if (error != null) ...[
          AppInlineError(message: error!),
          const SizedBox(height: AppSpacing.x12),
        ],
        team.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.x16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const AppInlineError(
            message: 'Не удалось загрузить команду',
          ),
          data: (state) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final m in state.members) ...[
                _MemberTile(
                  member: m,
                  onTap: busy ? null : () => onPick(m.userId),
                ),
                const SizedBox(height: AppSpacing.x6),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupPicker extends ConsumerWidget {
  const _GroupPicker({
    required this.projectId,
    required this.selected,
    required this.title,
    required this.onToggle,
    required this.onCreate,
    required this.error,
    required this.busy,
  });

  final String projectId;
  final Set<String> selected;
  final TextEditingController title;
  final ValueChanged<String> onToggle;
  final VoidCallback onCreate;
  final String? error;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamControllerProvider(projectId));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Групповой чат',
          subtitle: 'Выберите участников и дайте название',
        ),
        AppInput(
          controller: title,
          placeholder: 'Название (например, «Электрика»)',
        ),
        const SizedBox(height: AppSpacing.x12),
        if (error != null) ...[
          AppInlineError(message: error!),
          const SizedBox(height: AppSpacing.x12),
        ],
        team.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.x16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const AppInlineError(
            message: 'Не удалось загрузить команду',
          ),
          data: (state) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final m in state.members) ...[
                _MemberTile(
                  member: m,
                  selected: selected.contains(m.userId),
                  onTap: () => onToggle(m.userId),
                ),
                const SizedBox(height: AppSpacing.x6),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x12),
        AppButton(
          label: busy ? 'Создаём…' : 'Создать группу (${selected.length})',
          onPressed: busy ? null : onCreate,
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    this.selected = false,
    this.onTap,
  });

  final Membership member;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = member.user == null
        ? 'Участник'
        : '${member.user!.firstName} ${member.user!.lastName}'.trim();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLight : AppColors.n0,
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.n200,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.brandLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTextStyles.subtitle
                    .copyWith(color: AppColors.brand),
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.subtitle),
                  Text(
                    member.role.displayName,
                    style:
                        AppTextStyles.tiny.copyWith(color: AppColors.n500),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.brand,
              ),
          ],
        ),
      ),
    );
  }
}
