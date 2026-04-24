import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/payments_controller.dart';
import '../domain/payment.dart';
import 'payment_card.dart';

final _statusFilterProvider =
    StateProvider.autoDispose<PaymentStatus?>((_) => null);

/// s-budget-payments — список выплат проекта.
class PaymentsListScreen extends ConsumerWidget {
  const PaymentsListScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymentsControllerProvider(projectId));
    final filter = ref.watch(_statusFilterProvider);

    return AppScaffold(
      showBack: true,
      title: 'Выплаты',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded),
          onPressed: () =>
              context.push('/projects/$projectId/payments/new'),
        ),
      ],
      body: Column(
        children: [
          _FilterChips(
            selected: filter,
            onChanged: (v) =>
                ref.read(_statusFilterProvider.notifier).state = v,
          ),
          Expanded(
            child: async.when(
              loading: () =>
                  const AppLoadingState(skeleton: AppListSkeleton()),
              error: (e, _) => AppErrorState(
                title: 'Не удалось загрузить',
                onRetry: () =>
                    ref.invalidate(paymentsControllerProvider(projectId)),
              ),
              data: (items) {
                final filtered = filter == null
                    ? items
                    : items.where((p) => p.status == filter).toList();
                if (filtered.isEmpty) {
                  return AppEmptyState(
                    title: filter == null
                        ? 'Выплат ещё нет'
                        : 'Нет по этому фильтру',
                    subtitle: filter == null
                        ? 'Создайте первый аванс — отсюда запускается '
                            'цикл «заказчик → бригадир → мастер».'
                        : null,
                    icon: Icons.receipt_long_outlined,
                    actionLabel:
                        filter == null ? 'Новая выплата' : null,
                    onAction: filter == null
                        ? () => context.push(
                              '/projects/$projectId/payments/new',
                            )
                        : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref
                      .invalidate(paymentsControllerProvider(projectId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.x16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.x10),
                    itemBuilder: (_, i) => PaymentCard(
                      payment: filtered[i],
                      onTap: () => context.push('/payments/${filtered[i].id}'),
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
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});

  final PaymentStatus? selected;
  final ValueChanged<PaymentStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <_ChipSpec>[
      const _ChipSpec('Все', null),
      for (final s in PaymentStatus.values) _ChipSpec(s.displayName, s),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.x8),
        itemBuilder: (_, i) {
          final spec = chips[i];
          final active = spec.status == selected;
          return Center(
            child: GestureDetector(
              onTap: () => onChanged(spec.status),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x12,
                  vertical: AppSpacing.x6,
                ),
                decoration: BoxDecoration(
                  color: active ? AppColors.brand : AppColors.n100,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  spec.label,
                  style: AppTextStyles.caption.copyWith(
                    color: active ? AppColors.n0 : AppColors.n700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChipSpec {
  const _ChipSpec(this.label, this.status);
  final String label;
  final PaymentStatus? status;
}
