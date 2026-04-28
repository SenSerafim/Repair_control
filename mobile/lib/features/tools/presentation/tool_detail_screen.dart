import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/tools_controller.dart';
import '../domain/tool.dart';

/// s-tool-detail — детальная карточка инструмента.
class ToolDetailScreen extends ConsumerWidget {
  const ToolDetailScreen({required this.toolId, super.key});

  final String toolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(toolDetailProvider(toolId));

    return AppScaffold(
      showBack: true,
      title: 'Инструмент',
      backgroundColor: AppColors.n50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          subtitle: e.toString(),
          onRetry: () => ref.invalidate(toolDetailProvider(toolId)),
        ),
        data: (tool) => _Body(tool: tool),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.tool});

  final ToolItem tool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issued = tool.issuedQty > 0;
    final iconBg = issued ? AppColors.yellowBg : AppColors.greenLight;
    final iconColor = issued ? AppColors.yellowText : AppColors.greenDark;
    final statusText = issued ? 'Выдан' : 'На складе';
    final statusColor = issued ? AppColors.yellowText : AppColors.greenDark;
    final df = DateFormat('dd.MM.yyyy');

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x20),
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.r16),
              ),
              child: Icon(
                PhosphorIconsFill.wrench,
                size: 28,
                color: iconColor,
              ),
            ),
            const SizedBox(width: AppSpacing.x14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tool.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.n800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x20),
        Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            color: AppColors.n0,
            borderRadius: AppRadius.card,
            boxShadow: AppShadows.sh1,
          ),
          child: Column(
            children: [
              _DetailRow(label: 'Количество', value: '${tool.totalQty}'),
              const _Divider(),
              _DetailRow(label: 'Выдано', value: '${tool.issuedQty}'),
              const _Divider(),
              _DetailRow(label: 'На складе', value: '${tool.availableQty}'),
              const _Divider(),
              _DetailRow(
                label: 'Создан',
                value: df.format(tool.createdAt),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'ИСТОРИЯ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.n400,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x10),
        _Timeline(tool: tool),
        const SizedBox(height: AppSpacing.x32),
        AppButton(
          label: 'Удалить инструмент',
          variant: AppButtonVariant.ghostDanger,
          icon: PhosphorIconsRegular.trash,
          onPressed: tool.issuedQty > 0
              ? null
              : () async {
                  final failure = await ref
                      .read(myToolsProvider.notifier)
                      .remove(tool.id);
                  if (!context.mounted) return;
                  if (failure != null) {
                    AppToast.show(
                      context,
                      message: failure.userMessage,
                      kind: AppToastKind.error,
                    );
                  } else {
                    AppToast.show(context, message: '🗑 Удалено');
                    context.pop();
                  }
                },
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.n400,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.n800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.n100);
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.tool});

  final ToolItem tool;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy HH:mm');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        children: [
          if (tool.issuedQty > 0)
            _TimelineRow(
              dotColor: AppColors.yellowText,
              text: 'Выдан (${tool.issuedQty} шт.)',
              dateText: df.format(tool.updatedAt),
            ),
          if (tool.issuedQty > 0)
            const SizedBox(height: AppSpacing.x12),
          _TimelineRow(
            dotColor: AppColors.greenDark,
            text: 'Добавлен в список',
            dateText: df.format(tool.createdAt),
            last: true,
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.dotColor,
    required this.text,
    required this.dateText,
    this.last = false,
  });

  final Color dotColor;
  final String text;
  final String dateText;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!last)
              Container(
                width: 2,
                height: 32,
                color: AppColors.n200,
                margin: const EdgeInsets.only(top: 4),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.n800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.n400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
