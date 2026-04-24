import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/presentation/money_input.dart';
import '../application/selfpurchase_controller.dart';
import '../domain/self_purchase.dart';

class SelfpurchasesScreen extends ConsumerWidget {
  const SelfpurchasesScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(selfpurchasesControllerProvider(projectId));

    return AppScaffold(
      showBack: true,
      title: 'Самозакупы',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded),
          onPressed: () => _showCreate(context, ref),
        ),
      ],
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () =>
              ref.invalidate(selfpurchasesControllerProvider(projectId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              title: 'Самозакупов ещё нет',
              subtitle:
                  'Мастер или бригадир купил сам — создайте отчёт, чтобы '
                  'компенсировали после одобрения.',
              icon: Icons.shopping_bag_outlined,
              actionLabel: 'Создать',
              onAction: () => _showCreate(context, ref),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref
                .invalidate(selfpurchasesControllerProvider(projectId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.x16),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.x10),
              itemBuilder: (_, i) => _Card(
                sp: items[i],
                onTap: () => _showDetail(context, ref, items[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCreate(BuildContext context, WidgetRef ref) async {
    final amount = TextEditingController();
    final comment = TextEditingController();
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
              title: 'Самозакуп',
              subtitle: 'После одобрения сумма попадёт в бюджет.',
            ),
            MoneyInput(controller: amount, label: 'Сумма'),
            const SizedBox(height: AppSpacing.x12),
            const Text('Комментарий', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.x6),
            TextField(
              controller: comment,
              maxLines: 3,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: 'Что купили, где',
                filled: true,
                fillColor: AppColors.n0,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  borderSide: const BorderSide(
                    color: AppColors.n200,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x16),
            Builder(
              builder: (ctx) => AppButton(
                label: 'Отправить на согласование',
                onPressed: () async {
                  final kop = MoneyInput.readKopecks(amount);
                  if (kop == null || kop <= 0) return;
                  final failure = await ref
                      .read(
                        selfpurchasesControllerProvider(projectId)
                            .notifier,
                      )
                      .create(
                        amount: kop,
                        comment: comment.text.trim().isEmpty
                            ? null
                            : comment.text.trim(),
                      );
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  if (!context.mounted) return;
                  AppToast.show(
                    context,
                    message: failure == null
                        ? 'Отправлено'
                        : failure.userMessage,
                    kind: failure == null
                        ? AppToastKind.success
                        : AppToastKind.error,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    comment.dispose();
  }

  Future<void> _showDetail(
    BuildContext context,
    WidgetRef ref,
    SelfPurchase sp,
  ) async {
    await showAppBottomSheet<void>(
      context: context,
      child: _DetailBody(sp: sp),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.sp, required this.onTap});

  final SelfPurchase sp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sp.status.semaphore.bg,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: sp.status.semaphore.text,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Money.format(sp.amount),
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      StatusPill(
                        label: sp.status.displayName,
                        semaphore: sp.status.semaphore,
                      ),
                      const SizedBox(width: AppSpacing.x6),
                      Text(
                        sp.byRole.displayName,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  if (sp.comment?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(
                      sp.comment!,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.sp});
  final SelfPurchase sp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBottomSheetHeader(
          title: Money.format(sp.amount),
          subtitle:
              '${sp.byRole.displayName} · ${DateFormat('d MMM y HH:mm', 'ru').format(sp.createdAt)}',
        ),
        Row(
          children: [
            StatusPill(
              label: sp.status.displayName,
              semaphore: sp.status.semaphore,
            ),
          ],
        ),
        if (sp.comment?.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.x12),
          Container(
            padding: const EdgeInsets.all(AppSpacing.x12),
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: AppRadius.card,
            ),
            child: Text(sp.comment!, style: AppTextStyles.body),
          ),
        ],
        if (sp.decisionComment?.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.x12),
          Text(
            sp.status == SelfPurchaseStatus.approved
                ? 'Комментарий одобрившего'
                : 'Причина отказа',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 4),
          Text(sp.decisionComment!, style: AppTextStyles.body),
        ],
        if (sp.status == SelfPurchaseStatus.pending) ...[
          const SizedBox(height: AppSpacing.x16),
          AppButton(
            label: 'Одобрить',
            variant: AppButtonVariant.success,
            onPressed: () async {
              await ref
                  .read(
                    selfpurchasesControllerProvider(sp.projectId)
                        .notifier,
                  )
                  .approve(id: sp.id);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: AppSpacing.x8),
          AppButton(
            label: 'Отклонить',
            variant: AppButtonVariant.destructive,
            onPressed: () async {
              await ref
                  .read(
                    selfpurchasesControllerProvider(sp.projectId)
                        .notifier,
                  )
                  .reject(id: sp.id);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ],
    );
  }
}
