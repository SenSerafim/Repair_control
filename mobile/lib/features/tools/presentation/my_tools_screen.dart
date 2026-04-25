import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/tools_controller.dart';
import '../domain/tool.dart';

class MyToolsScreen extends ConsumerWidget {
  const MyToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myToolsProvider);

    return AppScaffold(
      showBack: true,
      title: 'Мои инструменты',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded),
          onPressed: () => _showAdd(context, ref),
        ),
      ],
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () => ref.invalidate(myToolsProvider),
        ),
        data: (tools) {
          if (tools.isEmpty) {
            return AppEmptyState(
              title: 'Инструментов ещё нет',
              subtitle:
                  'Добавьте свой инструмент — потом его можно выдать мастеру '
                  'на объекте.',
              icon: Icons.construction_outlined,
              actionLabel: 'Добавить',
              onAction: () => _showAdd(context, ref),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myToolsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.x16),
              itemCount: tools.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.x10),
              itemBuilder: (_, i) => _ToolCard(
                tool: tools[i],
                onEdit: () => _showEdit(context, ref, tools[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAdd(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final qty = TextEditingController(text: '1');
    final unit = TextEditingController(text: 'шт');
    await showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBottomSheetHeader(
              title: 'Новый инструмент',
              subtitle: 'Добавится в ваш личный список.',
            ),
            TextField(
              controller: name,
              decoration: _dec('Название'),
            ),
            const SizedBox(height: AppSpacing.x10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: qty,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Количество'),
                  ),
                ),
                const SizedBox(width: AppSpacing.x8),
                Expanded(
                  child: TextField(
                    controller: unit,
                    decoration: _dec('Ед.'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x16),
            Builder(
              builder: (ctx) => AppButton(
                label: 'Добавить',
                onPressed: () async {
                  final total = int.tryParse(qty.text);
                  if (name.text.trim().isEmpty ||
                      total == null ||
                      total <= 0) {
                    return;
                  }
                  final failure =
                      await ref.read(myToolsProvider.notifier).create(
                            name: name.text.trim(),
                            totalQty: total,
                            unit: unit.text.trim().isEmpty
                                ? null
                                : unit.text.trim(),
                          );
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  if (!context.mounted) return;
                  if (failure != null) {
                    AppToast.show(
                      context,
                      message: failure.userMessage,
                      kind: AppToastKind.error,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    qty.dispose();
    unit.dispose();
  }

  Future<void> _showEdit(
    BuildContext context,
    WidgetRef ref,
    ToolItem tool,
  ) async {
    final name = TextEditingController(text: tool.name);
    final qty = TextEditingController(text: tool.totalQty.toString());
    final unit = TextEditingController(text: tool.unit ?? '');
    await showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBottomSheetHeader(
              title: 'Изменить инструмент',
              subtitle: 'Сейчас выдано: ${tool.issuedQty} шт. Уменьшить '
                  'totalQty ниже этого числа нельзя.',
            ),
            TextField(
              controller: name,
              decoration: _dec('Название'),
            ),
            const SizedBox(height: AppSpacing.x10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: qty,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Количество'),
                  ),
                ),
                const SizedBox(width: AppSpacing.x8),
                Expanded(
                  child: TextField(
                    controller: unit,
                    decoration: _dec('Ед.'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x16),
            Builder(
              builder: (ctx) => AppButton(
                label: 'Сохранить',
                onPressed: () async {
                  final total = int.tryParse(qty.text);
                  if (name.text.trim().isEmpty ||
                      total == null ||
                      total < tool.issuedQty) {
                    return;
                  }
                  final failure =
                      await ref.read(myToolsProvider.notifier).saveUpdate(
                            id: tool.id,
                            name: name.text.trim(),
                            totalQty: total,
                            unit: unit.text.trim().isEmpty
                                ? null
                                : unit.text.trim(),
                          );
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  if (!context.mounted) return;
                  if (failure != null) {
                    AppToast.show(
                      context,
                      message: failure.userMessage,
                      kind: AppToastKind.error,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    qty.dispose();
    unit.dispose();
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, required this.onEdit});
  final ToolItem tool;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x14),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200, width: 1.5),
          boxShadow: AppShadows.sh1,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: const Icon(
                Icons.construction_outlined,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tool.name, style: AppTextStyles.subtitle),
                  const SizedBox(height: 2),
                  Text(
                    'Доступно ${tool.availableQty} из ${tool.totalQty} ${tool.unit ?? ''}'
                        .trim(),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (tool.isAllIssued)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.yellowBg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Весь выдан',
                  style: AppTextStyles.tiny
                      .copyWith(color: AppColors.yellowText),
                ),
              ),
            const SizedBox(width: 6),
            const Icon(
              Icons.edit_outlined,
              color: AppColors.n400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _dec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
      filled: true,
      fillColor: AppColors.n0,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: const BorderSide(color: AppColors.n200, width: 1.5),
      ),
    );
