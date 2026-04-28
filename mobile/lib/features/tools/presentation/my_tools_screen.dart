import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/tools_controller.dart';
import '../domain/tool.dart';

/// s-profile-tools — список «Мои инструменты» со stat-bar и swipe-to-delete.
class MyToolsScreen extends ConsumerWidget {
  const MyToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myToolsProvider);

    return AppScaffold(
      showBack: true,
      title: 'Мои инструменты',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      actions: [
        IconButton(
          icon: Icon(PhosphorIconsBold.plus, color: AppColors.brand),
          onPressed: () => context.push(AppRoutes.profileToolAdd),
        ),
      ],
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () => ref.invalidate(myToolsProvider),
        ),
        data: (tools) {
          final total = tools.length;
          final issued =
              tools.where((t) => t.issuedQty > 0).length;
          final inStock = tools.where((t) => t.availableQty > 0).length;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myToolsProvider),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.x16),
              children: [
                _StatBar(total: total, issued: issued, inStock: inStock),
                const SizedBox(height: AppSpacing.x12),
                _Hint(),
                const SizedBox(height: AppSpacing.x16),
                if (tools.isEmpty)
                  AppEmptyState(
                    title: 'Инструментов ещё нет',
                    subtitle: 'Добавьте свой инструмент, чтобы выдавать '
                        'его мастерам на объекте.',
                    icon: PhosphorIconsFill.wrench,
                    actionLabel: 'Добавить',
                    onAction: () => context.push(AppRoutes.profileToolAdd),
                  )
                else
                  for (final tool in tools) ...[
                    _ToolCard(
                      tool: tool,
                      onTap: () => context.push(
                        AppRoutes.profileToolDetailWith(tool.id),
                      ),
                      onDelete: () => _confirmDelete(context, ref, tool),
                    ),
                    const SizedBox(height: AppSpacing.x10),
                  ],
                const SizedBox(height: AppSpacing.x24),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ToolItem tool,
  ) async {
    if (tool.issuedQty > 0) {
      AppToast.show(
        context,
        message: 'Нельзя удалить — инструмент выдан',
        kind: AppToastKind.error,
      );
      return;
    }
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

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.total,
    required this.issued,
    required this.inStock,
  });

  final int total;
  final int issued;
  final int inStock;

  @override
  Widget build(BuildContext context) {
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
            value: '$issued',
            label: 'ВЫДАНО',
            bg: AppColors.yellowBg,
            color: AppColors.yellowText,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Stat(
            value: '$inStock',
            label: 'НА СКЛАДЕ',
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

class _Hint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(PhosphorIconsRegular.info, size: 16, color: AppColors.brand),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Список переносится между проектами. Свайп влево — удалить.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.n700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.tool,
    required this.onTap,
    required this.onDelete,
  });

  final ToolItem tool;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final issued = tool.issuedQty > 0;
    final iconBg = issued ? AppColors.yellowBg : AppColors.greenLight;
    final iconColor = issued ? AppColors.yellowText : AppColors.greenDark;

    return Dismissible(
      key: ValueKey('tool-${tool.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.x16),
        decoration: BoxDecoration(
          color: AppColors.redDot,
          borderRadius: AppRadius.card,
        ),
        child: Icon(PhosphorIconsFill.trash, color: AppColors.n0),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Material(
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
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Icon(
                    PhosphorIconsFill.wrench,
                    color: iconColor,
                    size: 20,
                  ),
                ),
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
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Кол-во: ${tool.totalQty}${tool.unit != null ? ' ${tool.unit}' : ''} · '
                        '${issued ? 'Выдан' : 'На складе'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.n400,
                        ),
                      ),
                    ],
                  ),
                ),
                _Pill(
                  text: issued ? 'Выдан' : 'На складе',
                  bg: iconBg,
                  color: iconColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.bg, required this.color});

  final String text;
  final Color bg;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
