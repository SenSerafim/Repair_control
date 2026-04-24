import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/presentation/money_input.dart';
import '../application/materials_controller.dart';
import '../domain/material_request.dart';

class MaterialDetailScreen extends ConsumerWidget {
  const MaterialDetailScreen({
    required this.projectId,
    required this.requestId,
    super.key,
  });

  final String projectId;
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      materialsControllerProvider(projectId).select(
        (v) => v.whenData(
          (list) => list.cast<MaterialRequest?>().firstWhere(
                (r) => r?.id == requestId,
                orElse: () => null,
              ),
        ),
      ),
    );

    return AppScaffold(
      showBack: true,
      title: 'Заявка',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Ошибка',
          onRetry: () =>
              ref.invalidate(materialsControllerProvider(projectId)),
        ),
        data: (request) {
          if (request == null) {
            return const AppEmptyState(
              title: 'Заявка не найдена',
              icon: Icons.error_outline,
            );
          }
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref
                      .invalidate(materialsControllerProvider(projectId)),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.x16),
                    children: [
                      _Header(request: request),
                      if (request.comment?.isNotEmpty ?? false) ...[
                        const SizedBox(height: AppSpacing.x12),
                        _CommentCard(comment: request.comment!),
                      ],
                      const SizedBox(height: AppSpacing.x16),
                      const Text('Позиции', style: AppTextStyles.h2),
                      const SizedBox(height: AppSpacing.x8),
                      for (final item in request.items) ...[
                        _ItemRow(request: request, item: item),
                        const SizedBox(height: AppSpacing.x6),
                      ],
                      const SizedBox(height: AppSpacing.x20),
                    ],
                  ),
                ),
              ),
              _Actions(projectId: projectId, request: request),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.request});
  final MaterialRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(request.title, style: AppTextStyles.h1, maxLines: 3),
          const SizedBox(height: AppSpacing.x8),
          Row(
            children: [
              StatusPill(
                label: request.status.displayName,
                semaphore: request.status.semaphore,
              ),
              const SizedBox(width: AppSpacing.x8),
              Text(
                request.recipient.displayName,
                style: AppTextStyles.caption,
              ),
            ],
          ),
          if (request.totalBoughtPrice > 0) ...[
            const SizedBox(height: AppSpacing.x8),
            Text(
              'Куплено на ${Money.format(request.totalBoughtPrice)}',
              style: AppTextStyles.subtitle
                  .copyWith(color: AppColors.greenDark),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});
  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: AppRadius.card,
      ),
      child: Text(comment, style: AppTextStyles.body),
    );
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({required this.request, required this.item});

  final MaterialRequest request;
  final MaterialItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canMarkBought = !item.isBought &&
        (request.status == MaterialRequestStatus.open ||
            request.status == MaterialRequestStatus.partiallyBought);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: item.isBought ? AppColors.greenDot : AppColors.n200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.isBought ? AppColors.greenDot : AppColors.n100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.isBought ? Icons.check_rounded : Icons.shopping_cart_outlined,
              size: 14,
              color: item.isBought ? AppColors.n0 : AppColors.n500,
            ),
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.subtitle),
                Text(
                  '${_fmtQty(item.qty)} ${item.unit ?? ''}'
                          '${item.pricePerUnit != null ? ' · ${Money.format(item.pricePerUnit!)}/шт' : ''}'
                      .trim(),
                  style: AppTextStyles.caption,
                ),
                if (item.isBought && item.totalPrice != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Итого ${Money.format(item.totalPrice!)}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.greenDark),
                  ),
                ],
              ],
            ),
          ),
          if (canMarkBought)
            TextButton(
              onPressed: () => _showMarkBoughtSheet(context, ref),
              child: const Text('Купил'),
            ),
        ],
      ),
    );
  }

  static String _fmtQty(double qty) {
    if (qty == qty.truncateToDouble()) return qty.toInt().toString();
    return qty.toStringAsFixed(2);
  }

  Future<void> _showMarkBoughtSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    if (item.pricePerUnit != null) {
      MoneyInput.setFromKopecks(controller, item.pricePerUnit!);
    }
    await showAppBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomSheetHeader(
            title: 'Позиция куплена',
            subtitle: 'Укажите фактическую цену за единицу.',
          ),
          MoneyInput(controller: controller, label: 'Цена за единицу'),
          const SizedBox(height: AppSpacing.x16),
          Builder(
            builder: (sheetCtx) => AppButton(
              label: 'Отметить купленным',
              variant: AppButtonVariant.success,
              onPressed: () async {
                final price = MoneyInput.readKopecks(controller);
                if (price == null || price <= 0) return;
                final failure = await ref
                    .read(
                      materialsControllerProvider(request.projectId)
                          .notifier,
                    )
                    .markBought(
                      requestId: request.id,
                      itemId: item.id,
                      pricePerUnit: price,
                    );
                if (!sheetCtx.mounted) return;
                Navigator.of(sheetCtx).pop();
                if (failure != null && context.mounted) {
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
    );
    controller.dispose();
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.projectId, required this.request});

  final String projectId;
  final MaterialRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttons = <Widget>[];
    final ctrl =
        ref.read(materialsControllerProvider(projectId).notifier);

    switch (request.status) {
      case MaterialRequestStatus.draft:
        buttons.add(AppButton(
          label: 'Отправить заказчику/бригадиру',
          onPressed: () => ctrl.send(request.id),
        ));
      case MaterialRequestStatus.partiallyBought:
      case MaterialRequestStatus.bought:
        if (request.allItemsBought) {
          buttons.add(AppButton(
            label: 'Финализировать (в бюджет)',
            variant: AppButtonVariant.success,
            onPressed: () => ctrl.finalizeRequest(request.id),
          ));
        }
        buttons
          ..add(const SizedBox(height: AppSpacing.x8))
          ..add(AppButton(
            label: 'Открыть спор',
            variant: AppButtonVariant.destructive,
            onPressed: () => _dispute(context, ref),
          ));
      case MaterialRequestStatus.delivered:
        buttons.add(AppButton(
          label: 'Подтвердить доставку',
          variant: AppButtonVariant.success,
          onPressed: () => ctrl.confirmDelivery(request.id),
        ));
      case MaterialRequestStatus.disputed:
        buttons.add(AppButton(
          label: 'Разрешить спор',
          onPressed: () => _resolve(context, ref),
        ));
      case MaterialRequestStatus.open:
        buttons.add(AppButton(
          label: 'Открыть спор',
          variant: AppButtonVariant.destructive,
          onPressed: () => _dispute(context, ref),
        ));
      case MaterialRequestStatus.resolved:
      case MaterialRequestStatus.cancelled:
        return const SizedBox.shrink();
    }

    if (buttons.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x12,
        AppSpacing.x16,
        AppSpacing.x16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.n0,
        border: Border(top: BorderSide(color: AppColors.n200)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: buttons,
        ),
      ),
    );
  }

  Future<void> _dispute(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showAppBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppBottomSheetHeader(
            title: 'Открыть спор по заявке',
            subtitle: 'Опишите проблему — заморозим заявку до разрешения.',
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.x12),
            decoration: BoxDecoration(
              color: AppColors.redBg,
              border: Border.all(color: const Color(0xFFFECACA)),
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.report_problem_outlined,
                  size: 16,
                  color: AppColors.redDot,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Заявка будет заморожена, пока спор открыт.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.redDot,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: 'Что не так?',
              filled: true,
              fillColor: AppColors.n0,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                borderSide:
                    const BorderSide(color: AppColors.n200, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          Builder(
            builder: (ctx) => AppButton(
              label: 'Открыть спор',
              variant: AppButtonVariant.destructive,
              onPressed: () async {
                final reason = controller.text.trim();
                if (reason.isEmpty) return;
                await ref
                    .read(
                      materialsControllerProvider(projectId).notifier,
                    )
                    .dispute(id: request.id, reason: reason);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
            ),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref) async {
    await showAppBottomSheet<void>(
      context: context,
      child: _ResolveSheet(
        onSubmit: (resolution) async {
          await ref
              .read(materialsControllerProvider(projectId).notifier)
              .resolve(id: request.id, resolution: resolution);
        },
      ),
    );
  }
}

class _ResolveOption {
  const _ResolveOption(this.key, this.icon, this.title, this.subtitle);

  final String key;
  final IconData icon;
  final String title;
  final String subtitle;
}

class _ResolveSheet extends StatefulWidget {
  const _ResolveSheet({required this.onSubmit});

  final Future<void> Function(String resolution) onSubmit;

  @override
  State<_ResolveSheet> createState() => _ResolveSheetState();
}

class _ResolveSheetState extends State<_ResolveSheet> {
  static const _options = [
    _ResolveOption(
      'delivered',
      Icons.local_shipping_outlined,
      'Довезли остаток',
      'Недостающие позиции доставлены',
    ),
    _ResolveOption(
      'refund',
      Icons.payments_outlined,
      'Возврат денег',
      'Скорректировать сумму',
    ),
    _ResolveOption(
      'write_off',
      Icons.event_busy_outlined,
      'Списать',
      'Принять как есть, без компенсации',
    ),
  ];

  _ResolveOption _selected = _options.first;
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final text = _comment.text.trim();
    final resolution = text.isEmpty
        ? _selected.title
        : '${_selected.title}. $text';
    setState(() => _busy = true);
    try {
      await widget.onSubmit(resolution);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppBottomSheetHeader(
          title: 'Закрыть спор',
          subtitle: 'Как решён спор?',
        ),
        for (final o in _options) ...[
          _ResolveTile(
            option: o,
            selected: o == _selected,
            onTap: () => setState(() => _selected = o),
          ),
          const SizedBox(height: AppSpacing.x8),
        ],
        const SizedBox(height: AppSpacing.x6),
        TextField(
          controller: _comment,
          minLines: 2,
          maxLines: 5,
          maxLength: 2000,
          decoration: InputDecoration(
            hintText: 'Комментарий (необязательно)',
            filled: true,
            fillColor: AppColors.n50,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              borderSide:
                  const BorderSide(color: AppColors.n200, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(AppSpacing.x12),
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.brand,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Решение зафиксируется в ленте событий — изменить нельзя.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        AppButton(
          label: 'Подтвердить и закрыть',
          variant: AppButtonVariant.success,
          icon: Icons.check_rounded,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}

class _ResolveTile extends StatelessWidget {
  const _ResolveTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ResolveOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLight : AppColors.n0,
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.n200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          children: [
            Icon(
              option.icon,
              size: 20,
              color: selected ? AppColors.brand : AppColors.n500,
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: AppTextStyles.subtitle.copyWith(
                      color: selected ? AppColors.brand : AppColors.n700,
                    ),
                  ),
                  Text(
                    option.subtitle,
                    style: AppTextStyles.tiny.copyWith(
                      color: selected
                          ? AppColors.brand.withValues(alpha: 0.7)
                          : AppColors.n400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
