import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/widgets.dart';
import '../../onboarding/presentation/widgets/tour_anchor.dart';
import '../application/payments_controller.dart';
import '../domain/payment.dart';
import 'payment_card.dart';

final _kindFilterProvider = StateProvider.autoDispose<PaymentKind?>(
  (_) => null,
);

/// s-budget-payments — список выплат проекта.
class PaymentsListScreen extends ConsumerWidget {
  const PaymentsListScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymentsControllerProvider(projectId));
    final filter = ref.watch(_kindFilterProvider);

    return AppScaffold(
      showBack: true,
      title: 'Выплаты',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded),
          onPressed: () => context.push('/projects/$projectId/payments/new'),
        ),
      ],
      body: Column(
        children: [
          _FilterChips(
            selected: filter,
            onChanged: (v) => ref.read(_kindFilterProvider.notifier).state = v,
          ),
          Expanded(
            child: async.when(
              loading: () => const AppLoadingState(skeleton: AppListSkeleton()),
              error: (e, _) => AppErrorState(
                title: 'Не удалось загрузить',
                onRetry: () =>
                    ref.invalidate(paymentsControllerProvider(projectId)),
              ),
              data: (items) {
                final filtered = filter == null
                    ? items
                    : items.where((p) => p.kind == filter).toList();
                if (filtered.isEmpty) {
                  return AppEmptyState(
                    title: filter == null
                        ? 'Выплат ещё нет'
                        : 'Нет по этому фильтру',
                    subtitle: filter == null
                        ? 'Создайте первый платёж — заказчик может платить '
                              'напрямую бригадиру или мастеру.'
                        : null,
                    icon: Icons.receipt_long_outlined,
                    actionLabel: filter == null ? 'Новая выплата' : null,
                    onAction: filter == null
                        ? () =>
                              context.push('/projects/$projectId/payments/new')
                        : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(paymentsControllerProvider(projectId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.x16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.x10),
                    itemBuilder: (_, i) {
                      final card = PaymentCard(
                        payment: filtered[i],
                        onTap: () => context.push(
                          AppRoutes.paymentDetailWith(filtered[i].id),
                        ),
                      );
                      return i == 0
                          ? TourAnchor(
                              id: 'payments_list.first_payment',
                              child: card,
                            )
                          : card;
                    },
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

  final PaymentKind? selected;
  final ValueChanged<PaymentKind?> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <_ChipSpec>[
      const _ChipSpec('Все', null),
      for (final k in PaymentKind.values) _ChipSpec(k.displayName, k),
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
          final active = spec.kind == selected;
          return Center(
            child: GestureDetector(
              onTap: () => onChanged(spec.kind),
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
  const _ChipSpec(this.label, this.kind);
  final String label;
  final PaymentKind? kind;
}
