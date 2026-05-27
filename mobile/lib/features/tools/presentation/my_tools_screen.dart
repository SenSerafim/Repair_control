import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/tools_controller.dart';
import '../domain/tool.dart';

/// «Мои инструменты» в профиле пользователя. Self-custody модель:
/// здесь — только личные инструменты, НЕ привязанные к проектам.
/// Добавление в проект — отдельным флоу на доске проекта.
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
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myToolsProvider),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.x16),
              children: [
                _Hint(count: tools.length),
                const SizedBox(height: AppSpacing.x16),
                if (tools.isEmpty)
                  AppEmptyState(
                    title: 'Инструментов ещё нет',
                    subtitle:
                        'Добавьте свой инструмент — его можно будет добавить '
                        'в любой ваш проект одним нажатием.',
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

class _Hint extends StatelessWidget {
  const _Hint({required this.count});
  final int count;

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
          Expanded(
            child: Text(
              count == 0
                  ? 'Здесь будут ваши инструменты. Их можно добавить в проект на доске инструментов проекта.'
                  : 'Всего инструментов: $count. На доске проекта добавьте их одним нажатием.',
              style: const TextStyle(
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
                    color: AppColors.brandLight,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Icon(
                    PhosphorIconsFill.wrench,
                    color: AppColors.brand,
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
                      if (tool.serial != null && tool.serial!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '№ ${tool.serial}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.n400,
                          ),
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
      ),
    );
  }
}
