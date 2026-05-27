import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../projects/domain/membership.dart';
import '../../team/application/team_controller.dart';
import '../application/tools_controller.dart';
import '../domain/tool.dart';

/// Доска инструментов проекта (self-custody модель, 2026-05-12).
///   • Любой member видит список «кто сейчас держит каждый инструмент».
///   • Любой может self-claim («Я забрал»).
///   • Любой может добавить инструмент: из «Моих» или новый сразу в проекте.
///   • История передач — в детальной карточке.
class ProjectToolsScreen extends ConsumerWidget {
  const ProjectToolsScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectToolsBoardProvider(projectId));
    final me = ref.watch(authControllerProvider).userId;

    return AppScaffold(
      showBack: true,
      title: 'Инструменты',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: Stack(
        children: [
          async.when(
            loading: () => const AppLoadingState(),
            error: (e, _) => AppErrorState(
              title: 'Не удалось загрузить',
              onRetry: () =>
                  ref.invalidate(projectToolsBoardProvider(projectId)),
            ),
            data: (tools) => RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(projectToolsBoardProvider(projectId)),
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.x16),
                children: [
                  if (tools.isEmpty)
                    AppEmptyState(
                      title: 'Инструментов в проекте ещё нет',
                      subtitle:
                          'Добавьте свой инструмент или возьмите из «Мои инструменты». '
                          'Любой участник проекта может это сделать.',
                      icon: PhosphorIconsFill.wrench,
                      actionLabel: 'Добавить',
                      onAction: () => _showAddSheet(context, projectId),
                    )
                  else ...[
                    _SummaryBar(tools: tools, me: me),
                    const SizedBox(height: AppSpacing.x12),
                    for (final t in tools) ...[
                      _ToolBoardCard(
                        tool: t,
                        isHeldByMe: me != null && t.isHeldBy(me),
                        onTap: () => context.push(
                          AppRoutes.profileToolDetailWith(t.id),
                        ),
                        onClaim: me != null && !t.isHeldBy(me)
                            ? () => _claim(context, ref, t.id, projectId)
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.x10),
                    ],
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 16,
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.brand,
              foregroundColor: AppColors.n0,
              onPressed: () => _showAddSheet(context, projectId),
              icon: Icon(PhosphorIconsBold.plus),
              label: const Text('Добавить'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _claim(
    BuildContext context,
    WidgetRef ref,
    String toolId,
    String projectId,
  ) async {
    final failure = await ref
        .read(projectToolsBoardProvider(projectId).notifier)
        .claim(toolId: toolId);
    if (!context.mounted) return;
    if (failure != null) {
      AppToast.show(
        context,
        message: failure.userMessage,
        kind: AppToastKind.error,
      );
    } else {
      AppToast.show(
        context,
        message: 'Инструмент теперь у вас',
        kind: AppToastKind.success,
      );
    }
  }

  Future<void> _showAddSheet(BuildContext context, String projectId) async {
    await showAppBottomSheet<void>(
      context: context,
      child: _AddToolToProjectSheet(projectId: projectId),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.tools, required this.me});
  final List<ToolItem> tools;
  final String? me;

  @override
  Widget build(BuildContext context) {
    final total = tools.length;
    final myCount = me == null ? 0 : tools.where((t) => t.isHeldBy(me!)).length;
    return Row(
      children: [
        Expanded(
          child: _Stat(
            value: '$total',
            label: 'ВСЕГО',
            bg: AppColors.n0,
            color: AppColors.n800,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Stat(
            value: '$myCount',
            label: 'У МЕНЯ',
            bg: AppColors.greenLight,
            color: AppColors.greenDark,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.bg,
    required this.color,
  });
  final String value;
  final String label;
  final Color bg;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.75),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolBoardCard extends StatelessWidget {
  const _ToolBoardCard({
    required this.tool,
    required this.isHeldByMe,
    required this.onTap,
    this.onClaim,
  });

  final ToolItem tool;
  final bool isHeldByMe;
  final VoidCallback onTap;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final holderName = tool.holder?.displayName ?? '—';
    final ownerName = tool.owner?.displayName ?? '—';

    return Material(
      color: AppColors.n0,
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            border: Border.all(
              color: isHeldByMe ? AppColors.greenDark : AppColors.n200,
              width: isHeldByMe ? 1.5 : 1,
            ),
            borderRadius: AppRadius.card,
            boxShadow: AppShadows.sh1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isHeldByMe
                          ? AppColors.greenLight
                          : AppColors.brandLight,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                    child: Icon(
                      PhosphorIconsFill.wrench,
                      color: isHeldByMe ? AppColors.greenDark : AppColors.brand,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tool.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.n800,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                            if (isHeldByMe) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.greenLight,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                                child: const Text(
                                  '👤 Я',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.greenDark,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isHeldByMe ? 'Сейчас у вас' : 'Сейчас у: $holderName',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isHeldByMe
                                ? AppColors.greenDark
                                : AppColors.n700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Владелец: $ownerName'
                          '${tool.serial != null && tool.serial!.isNotEmpty ? ' · № ${tool.serial}' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.n400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (onClaim != null) ...[
                const SizedBox(height: AppSpacing.x10),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Я забрал',
                    icon: PhosphorIconsBold.handArrowDown,
                    variant: AppButtonVariant.secondary,
                    onPressed: onClaim,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────── AddToolToProjectSheet (внутренний компонент экрана) ───────────────

enum _AddMode { fromMy, brandNew }

class _AddToolToProjectSheet extends ConsumerStatefulWidget {
  const _AddToolToProjectSheet({required this.projectId});
  final String projectId;

  @override
  ConsumerState<_AddToolToProjectSheet> createState() =>
      _AddToolToProjectSheetState();
}

class _AddToolToProjectSheetState
    extends ConsumerState<_AddToolToProjectSheet> {
  _AddMode _mode = _AddMode.fromMy;
  final _name = TextEditingController();
  final _serial = TextEditingController();
  String? _selectedOwnerId;
  bool _busy = false;
  final Set<String> _selected = {};

  @override
  void dispose() {
    _name.dispose();
    _serial.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller =
        ref.read(projectToolsBoardProvider(widget.projectId).notifier);
    setState(() => _busy = true);

    if (_mode == _AddMode.fromMy) {
      if (_selected.isEmpty) {
        setState(() => _busy = false);
        AppToast.show(
          context,
          message: 'Выберите хотя бы один инструмент',
          kind: AppToastKind.error,
        );
        return;
      }
      final failure = await controller.attachFromMy(_selected.toList());
      if (!mounted) return;
      setState(() => _busy = false);
      if (failure != null) {
        AppToast.show(
          context,
          message: failure.userMessage,
          kind: AppToastKind.error,
        );
      } else {
        Navigator.of(context).pop();
        AppToast.show(
          context,
          message: 'Добавлено в проект',
          kind: AppToastKind.success,
        );
      }
    } else {
      final name = _name.text.trim();
      if (name.isEmpty) {
        setState(() => _busy = false);
        AppToast.show(
          context,
          message: 'Введите название',
          kind: AppToastKind.error,
        );
        return;
      }
      final failure = await controller.createInProject(
        name: name,
        ownerId: _selectedOwnerId,
        serial: _serial.text.trim().isEmpty ? null : _serial.text.trim(),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (failure != null) {
        AppToast.show(
          context,
          message: failure.userMessage,
          kind: AppToastKind.error,
        );
      } else {
        Navigator.of(context).pop();
        AppToast.show(
          context,
          message: 'Инструмент добавлен',
          kind: AppToastKind.success,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x16,
          AppSpacing.x8,
          AppSpacing.x16,
          AppSpacing.x16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBottomSheetHeader(title: 'Добавить инструмент'),
            _ModeSwitch(
              value: _mode,
              onChanged: (v) => setState(() => _mode = v),
            ),
            const SizedBox(height: AppSpacing.x12),
            if (_mode == _AddMode.fromMy)
              _FromMyContent(
                selected: _selected,
                onToggle: (id, on) => setState(() {
                  if (on) {
                    _selected.add(id);
                  } else {
                    _selected.remove(id);
                  }
                }),
              )
            else
              _BrandNewContent(
                name: _name,
                serial: _serial,
                projectId: widget.projectId,
                selectedOwnerId: _selectedOwnerId,
                onOwnerChanged: (v) => setState(() => _selectedOwnerId = v),
              ),
            const SizedBox(height: AppSpacing.x14),
            AppButton(
              label: _mode == _AddMode.fromMy
                  ? (_selected.isEmpty
                      ? 'Выберите инструменты'
                      : 'Добавить (${_selected.length})')
                  : 'Добавить в проект',
              icon: PhosphorIconsBold.check,
              isLoading: _busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.value, required this.onChanged});
  final _AddMode value;
  final ValueChanged<_AddMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: 'Из моих',
              active: value == _AddMode.fromMy,
              onTap: () => onChanged(_AddMode.fromMy),
            ),
          ),
          Expanded(
            child: _Tab(
              label: 'Новый',
              active: value == _AddMode.brandNew,
              onTap: () => onChanged(_AddMode.brandNew),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.n0 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.r8),
          boxShadow: active ? AppShadows.sh1 : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? AppColors.n800 : AppColors.n400,
          ),
        ),
      ),
    );
  }
}

class _FromMyContent extends ConsumerWidget {
  const _FromMyContent({required this.selected, required this.onToggle});
  final Set<String> selected;
  final void Function(String id, bool on) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myToolsProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: AppErrorState(
          title: 'Не удалось загрузить «Мои инструменты»',
          onRetry: () => ref.invalidate(myToolsProvider),
        ),
      ),
      data: (tools) {
        final available = tools.where((t) => !t.isInProject).toList();
        if (available.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  'В вашем профиле нет свободных инструментов',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.n700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6),
                Text(
                  'Перейдите на вкладку «Новый», чтобы создать инструмент сразу в этом проекте.',
                  style: TextStyle(fontSize: 11, color: AppColors.n400),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final t in available)
                _SelectableRow(
                  tool: t,
                  selected: selected.contains(t.id),
                  onChanged: (on) => onToggle(t.id, on),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({
    required this.tool,
    required this.selected,
    required this.onChanged,
  });

  final ToolItem tool;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!selected),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.n0,
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.n200,
          ),
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? PhosphorIconsFill.checkSquare
                  : PhosphorIconsRegular.square,
              color: selected ? AppColors.brand : AppColors.n300,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tool.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.n800,
                    ),
                  ),
                  if (tool.serial != null && tool.serial!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '№ ${tool.serial}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.n400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandNewContent extends ConsumerWidget {
  const _BrandNewContent({
    required this.name,
    required this.serial,
    required this.projectId,
    required this.selectedOwnerId,
    required this.onOwnerChanged,
  });

  final TextEditingController name;
  final TextEditingController serial;
  final String projectId;
  final String? selectedOwnerId;
  final ValueChanged<String?> onOwnerChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teamControllerProvider(projectId));
    final me = ref.watch(authControllerProvider).userId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppInput(
          controller: name,
          label: 'Название',
          placeholder: 'Например: Перфоратор Bosch GBH 2-26',
        ),
        const SizedBox(height: AppSpacing.x12),
        AppInput(
          controller: serial,
          label: 'Серийный номер',
          placeholder: 'Опционально',
        ),
        const SizedBox(height: AppSpacing.x12),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Кому будет принадлежать инструмент',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.n700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        async.when(
          loading: () => const SizedBox(
            height: 56,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => const Text(
            'Не удалось загрузить команду',
            style: TextStyle(fontSize: 11, color: AppColors.redDot),
          ),
          data: (teamState) {
            final members = teamState.members;
            final effective = selectedOwnerId ?? me;
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final m in members)
                    _OwnerRow(
                      title: _displayName(m),
                      role: m.role.displayName,
                      isMe: m.userId == me,
                      selected: effective == m.userId,
                      onTap: () => onOwnerChanged(m.userId),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _displayName(Membership m) {
    final u = m.user;
    if (u == null) return m.userId;
    final s = '${u.firstName} ${u.lastName}'.trim();
    return s.isEmpty ? m.userId : s;
  }
}

class _OwnerRow extends StatelessWidget {
  const _OwnerRow({
    required this.title,
    required this.role,
    required this.isMe,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String role;
  final bool isMe;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLight : AppColors.n0,
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.n200,
          ),
          borderRadius: BorderRadius.circular(AppRadius.r8),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? PhosphorIconsFill.radioButton
                  : PhosphorIconsRegular.circle,
              color: selected ? AppColors.brand : AppColors.n300,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isMe ? '$title (вы)' : title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.n800,
                ),
              ),
            ),
            Text(
              role,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.n400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
