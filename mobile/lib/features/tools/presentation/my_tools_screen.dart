import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/tools_controller.dart';
import '../domain/tool.dart';

/// «Мои инструменты» в профиле пользователя (NEWFIX-2 §7.2).
/// - Поиск по `name` сверху списка
/// - Чипсы-фильтры: Все · На складе · На объекте · У сотр.
/// - Меню ⋮ на строке: Редактировать, Удалить, Сменить статус
class MyToolsScreen extends ConsumerStatefulWidget {
  const MyToolsScreen({super.key});

  @override
  ConsumerState<MyToolsScreen> createState() => _MyToolsScreenState();
}

class _MyToolsScreenState extends ConsumerState<MyToolsScreen> {
  final TextEditingController _search = TextEditingController();
  ToolStatus? _statusFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(myToolsProvider);
    final filteredAsync = ref.watch(
      filteredMyToolsProvider((
        search: _search.text.trim().isEmpty ? null : _search.text.trim(),
        status: _statusFilter,
      )),
    );
    final counts = _counts(allAsync.valueOrNull ?? const <ToolItem>[]);

    return AppScaffold(
      showBack: true,
      title: 'Мои инструменты',
      backgroundColor: AppColors.n50,
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: Icon(PhosphorIconsBold.plus, color: AppColors.brand),
          onPressed: () => context.push(AppRoutes.profileToolAdd),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x16,
              AppSpacing.x12,
              AppSpacing.x16,
              AppSpacing.x8,
            ),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Поиск по названию…',
                prefixIcon: Icon(
                  PhosphorIconsRegular.magnifyingGlass,
                  size: 18,
                  color: AppColors.n400,
                ),
                filled: true,
                fillColor: AppColors.n0,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  borderSide: const BorderSide(color: AppColors.n200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  borderSide: const BorderSide(color: AppColors.n200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  borderSide: const BorderSide(color: AppColors.brand),
                ),
              ),
            ),
          ),
          _FilterBar(
            selected: _statusFilter,
            counts: counts,
            onChanged: (v) => setState(() => _statusFilter = v),
          ),
          Expanded(
            child: filteredAsync.when(
              loading: () => const AppLoadingState(),
              error: (e, _) => AppErrorState(
                title: 'Не удалось загрузить',
                onRetry: () {
                  ref
                    ..invalidate(myToolsProvider)
                    ..invalidate(filteredMyToolsProvider);
                },
              ),
              data: (tools) {
                if (tools.isEmpty) {
                  return AppEmptyState(
                    title: _emptyTitle,
                    subtitle: _emptySubtitle,
                    icon: PhosphorIconsFill.wrench,
                    actionLabel: 'Добавить',
                    onAction: () => context.push(AppRoutes.profileToolAdd),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref
                      ..invalidate(myToolsProvider)
                      ..invalidate(filteredMyToolsProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.x16,
                      AppSpacing.x8,
                      AppSpacing.x16,
                      AppSpacing.x24,
                    ),
                    itemCount: tools.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.x10),
                    itemBuilder: (_, i) => _ToolCard(
                      tool: tools[i],
                      onTap: () => context.push(
                        AppRoutes.profileToolDetailWith(tools[i].id),
                      ),
                      onMenu: () => _showMenu(context, ref, tools[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String get _emptyTitle => switch (_statusFilter) {
    null => 'Инструментов ещё нет',
    ToolStatus.inStorage => 'На складе пусто',
    ToolStatus.onProject => 'На объектах нет инструментов',
    ToolStatus.withEmployee => 'У сотрудников нет инструментов',
  };

  String get _emptySubtitle =>
      'Добавьте инструмент — артикул, фото, серийник, статус и куда он сейчас положен.';

  _Counts _counts(List<ToolItem> all) {
    var inStorage = 0;
    var onProject = 0;
    var withEmployee = 0;
    for (final t in all) {
      switch (t.status) {
        case ToolStatus.inStorage:
          inStorage++;
        case ToolStatus.onProject:
          onProject++;
        case ToolStatus.withEmployee:
          withEmployee++;
      }
    }
    return _Counts(
      total: all.length,
      inStorage: inStorage,
      onProject: onProject,
      withEmployee: withEmployee,
    );
  }

  Future<void> _showMenu(
    BuildContext context,
    WidgetRef ref,
    ToolItem tool,
  ) async {
    final action = await showAppBottomSheet<_ToolMenuAction>(
      context: context,
      child: Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBottomSheetHeader(title: tool.name),
            _MenuItem(
              icon: PhosphorIconsRegular.pencilSimple,
              label: 'Редактировать',
              onTap: () => Navigator.of(ctx).pop(_ToolMenuAction.edit),
            ),
            _MenuItem(
              icon: PhosphorIconsRegular.arrowsClockwise,
              label: 'Сменить статус',
              onTap: () => Navigator.of(ctx).pop(_ToolMenuAction.changeStatus),
            ),
            // Task 6.2 — открывает full-screen timeline передач инструмента.
            _MenuItem(
              icon: PhosphorIconsRegular.clockCounterClockwise,
              label: 'История',
              onTap: () => Navigator.of(ctx).pop(_ToolMenuAction.history),
            ),
            _MenuItem(
              icon: PhosphorIconsRegular.trash,
              label: 'Удалить',
              danger: true,
              onTap: () => Navigator.of(ctx).pop(_ToolMenuAction.delete),
            ),
          ],
        ),
      ),
    );
    if (action == null) return;
    if (!context.mounted) return;
    switch (action) {
      case _ToolMenuAction.edit:
        await context.push<void>(AppRoutes.profileToolDetailWith(tool.id));
      case _ToolMenuAction.changeStatus:
        await _changeStatusSheet(context, ref, tool);
      case _ToolMenuAction.history:
        await context.push<void>(
          AppRoutes.toolCustodyHistoryWith(tool.id, name: tool.name),
        );
      case _ToolMenuAction.delete:
        await _confirmDelete(context, ref, tool);
    }
  }

  Future<void> _changeStatusSheet(
    BuildContext context,
    WidgetRef ref,
    ToolItem tool,
  ) async {
    final newStatus = await showAppBottomSheet<ToolStatus>(
      context: context,
      child: Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBottomSheetHeader(title: 'Куда переводим?'),
            for (final st in [ToolStatus.inStorage, ToolStatus.withEmployee])
              _MenuItem(
                icon: PhosphorIconsRegular.tag,
                label: st.displayName,
                onTap: () => Navigator.of(ctx).pop(st),
              ),
          ],
        ),
      ),
    );
    if (newStatus == null || !context.mounted) return;
    // on_project статус устанавливается только через attach в проекте,
    // здесь его не предлагаем (см. §8/§9).
    if (newStatus == ToolStatus.withEmployee) {
      AppToast.show(
        context,
        message:
            'Выдайте инструмент через профиль сотрудника — открой Чаты → Команда.',
        kind: AppToastKind.info,
      );
      return;
    }
    final failure = await ref
        .read(myToolsProvider.notifier)
        .saveUpdate(id: tool.id, status: newStatus);
    if (!context.mounted) return;
    if (failure != null) {
      AppToast.show(
        context,
        message: failure.userMessage,
        kind: AppToastKind.error,
      );
    } else {
      AppToast.show(context, message: 'Статус обновлён');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ToolItem tool,
  ) async {
    final ok = await showAppBottomSheet<bool>(
      context: context,
      child: Builder(
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBottomSheetHeader(
              title: 'Удалить «${tool.name}»?',
              subtitle: 'Действие нельзя отменить.',
            ),
            AppButton(
              label: 'Удалить',
              variant: AppButtonVariant.destructive,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: AppSpacing.x8),
            AppButton(
              label: 'Отмена',
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      ),
    );
    if (ok ?? false) {
      final failure = await ref.read(myToolsProvider.notifier).remove(tool.id);
      if (!context.mounted) return;
      if (failure != null) {
        AppToast.show(
          context,
          message: failure.userMessage,
          kind: AppToastKind.error,
        );
      } else {
        AppToast.show(context, message: 'Удалено');
      }
    }
  }
}

enum _ToolMenuAction { edit, changeStatus, history, delete }

class _Counts {
  const _Counts({
    required this.total,
    required this.inStorage,
    required this.onProject,
    required this.withEmployee,
  });
  final int total;
  final int inStorage;
  final int onProject;
  final int withEmployee;
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  final ToolStatus? selected;
  final _Counts counts;
  final ValueChanged<ToolStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppFilterPillBar(
      chips: [
        AppFilterPillSpec(id: 'all', label: 'Все · ${counts.total}'),
        AppFilterPillSpec(
          id: ToolStatus.inStorage.apiValue,
          label: 'Склад · ${counts.inStorage}',
        ),
        AppFilterPillSpec(
          id: ToolStatus.onProject.apiValue,
          label: 'Объект · ${counts.onProject}',
        ),
        AppFilterPillSpec(
          id: ToolStatus.withEmployee.apiValue,
          label: 'У сотр. · ${counts.withEmployee}',
        ),
      ],
      activeId: selected?.apiValue ?? 'all',
      onSelect: (id) {
        switch (id) {
          case 'in_storage':
            onChanged(ToolStatus.inStorage);
          case 'on_project':
            onChanged(ToolStatus.onProject);
          case 'with_employee':
            onChanged(ToolStatus.withEmployee);
          case 'all':
          default:
            onChanged(null);
        }
      },
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.redText : AppColors.n800;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.x14,
            horizontal: AppSpacing.x4,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: AppSpacing.x12),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.tool,
    required this.onTap,
    required this.onMenu,
  });

  final ToolItem tool;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.n0,
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.n200),
            borderRadius: AppRadius.card,
            boxShadow: AppShadows.sh1,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PhotoOrIcon(photoKey: tool.photoKey),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tool.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.n800,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tool.serial != null && tool.serial!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Серийный: ${tool.serial}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.n500,
                        ),
                      ),
                    ],
                    if (tool.article != null && tool.article!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Артикул: ${tool.article}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.n400,
                        ),
                      ),
                    ],
                    if (tool.purchaseDate != null ||
                        tool.condition != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (tool.condition != null)
                            _ConditionPill(condition: tool.condition!),
                          if (tool.condition != null &&
                              tool.purchaseDate != null)
                            const SizedBox(width: 6),
                          if (tool.purchaseDate != null)
                            Text(
                              'куплен ${DateFormat('MM.y').format(tool.purchaseDate!)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.n500,
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    _StatusLine(tool: tool),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  PhosphorIconsRegular.dotsThreeOutline,
                  color: AppColors.n400,
                ),
                tooltip: 'Действия',
                onPressed: onMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoOrIcon extends StatelessWidget {
  const _PhotoOrIcon({this.photoKey});
  final String? photoKey;

  @override
  Widget build(BuildContext context) {
    // photoKey пока хранится как S3-key. Рендеринг через presigned URL — задача
    // tool_detail_screen / отдельного presign-провайдера; здесь оставляем
    // плейсхолдер-иконку, чтобы карточка не блокировалась загрузкой.
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Icon(
        photoKey == null ? PhosphorIconsFill.wrench : PhosphorIconsFill.camera,
        color: AppColors.brand,
        size: 22,
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.tool});
  final ToolItem tool;

  @override
  Widget build(BuildContext context) {
    final color = switch (tool.status) {
      ToolStatus.inStorage => AppColors.n500,
      ToolStatus.onProject => AppColors.greenDark,
      ToolStatus.withEmployee => AppColors.brand,
    };
    final label = switch (tool.status) {
      ToolStatus.inStorage =>
        tool.storageLocation != null && tool.storageLocation!.isNotEmpty
            ? 'На складе: ${tool.storageLocation}'
            : 'На складе',
      ToolStatus.onProject => 'На объекте',
      ToolStatus.withEmployee =>
        tool.holder?.displayName != null
            ? 'У сотрудника: ${tool.holder!.displayName}'
            : 'У сотрудника',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _ConditionPill extends StatelessWidget {
  const _ConditionPill({required this.condition});

  final ToolCondition condition;

  @override
  Widget build(BuildContext context) {
    final color = switch (condition) {
      ToolCondition.newTool => AppColors.greenDark,
      ToolCondition.good => AppColors.brand,
      ToolCondition.worn => AppColors.yellowText,
      ToolCondition.broken => AppColors.redText,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        condition.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
