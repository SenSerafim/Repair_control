import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../application/payments_controller.dart';
import '../domain/payment.dart';
import 'payment_sheets.dart';

/// e-pay-pending / e-pay-confirmed / e-pay-dispute / e-pay-disputed /
/// s-budget-payment-* — унифицированный экран детали.
class PaymentDetailScreen extends ConsumerWidget {
  const PaymentDetailScreen({required this.paymentId, super.key});

  final String paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymentDetailProvider(paymentId));
    final me = ref.watch(authControllerProvider).userId;

    return AppScaffold(
      showBack: true,
      title: 'Выплата',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () => ref.invalidate(paymentDetailProvider(paymentId)),
        ),
        data: (p) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(paymentDetailProvider(paymentId)),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.x16),
                  children: [
                    Hero(
                      tag: 'payment-${p.id}',
                      flightShuttleBuilder: (_, __, dir, fromCtx, toCtx) {
                        final hero = (dir == HeroFlightDirection.push
                                ? fromCtx
                                : toCtx)
                            .widget as Hero;
                        return hero.child;
                      },
                      child: const SizedBox(height: 1),
                    ),
                    _AmountHeader(payment: p),
                    const SizedBox(height: AppSpacing.x12),
                    _InfoCard(payment: p),
                    if (p.comment != null && p.comment!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.x12),
                      _CommentCard(comment: p.comment!),
                    ],
                    if (p.children.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.x16),
                      const Text('Распределение', style: AppTextStyles.h2),
                      const SizedBox(height: AppSpacing.x8),
                      for (final c in p.children) ...[
                        _ChildRow(payment: c),
                        const SizedBox(height: AppSpacing.x6),
                      ],
                    ],
                    if (p.disputes.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.x16),
                      const Text('Споры', style: AppTextStyles.h2),
                      const SizedBox(height: AppSpacing.x8),
                      for (final d in p.disputes) ...[
                        _DisputeRow(dispute: d),
                        const SizedBox(height: AppSpacing.x6),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.x20),
                  ],
                ),
              ),
            ),
            _Actions(payment: p, meId: me),
          ],
        ),
      ),
    );
  }
}

class _AmountHeader extends StatelessWidget {
  const _AmountHeader({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            payment.status.semaphore.dot.withValues(alpha: 0.88),
            AppColors.brandDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.r24),
        boxShadow: AppShadows.shBlue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(
            label: payment.status.displayName,
            semaphore: payment.status.semaphore,
          ),
          const SizedBox(height: AppSpacing.x10),
          Text(
            Money.format(payment.effectiveAmount),
            style: AppTextStyles.screenTitle
                .copyWith(color: AppColors.n0, fontSize: 32),
          ),
          const SizedBox(height: 2),
          Text(
            payment.kind.displayName,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.brandLight),
          ),
          if (payment.resolvedAmount != null &&
              payment.resolvedAmount != payment.amount) ...[
            const SizedBox(height: AppSpacing.x6),
            Text(
              'Изначально было ${Money.format(payment.amount)}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.brandLight),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.payment});

  final Payment payment;

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
        children: [
          _row('От', _shorten(payment.fromUserId)),
          const Divider(height: AppSpacing.x20, color: AppColors.n100),
          _row('Кому', _shorten(payment.toUserId)),
          const Divider(height: AppSpacing.x20, color: AppColors.n100),
          _row(
            'Создано',
            DateFormat('d MMMM y · HH:mm', 'ru').format(payment.createdAt),
          ),
          if (payment.confirmedAt != null) ...[
            const Divider(height: AppSpacing.x20, color: AppColors.n100),
            _row(
              'Подтверждено',
              DateFormat('d MMMM y · HH:mm', 'ru')
                  .format(payment.confirmedAt!),
            ),
          ],
          if (payment.children.isNotEmpty) ...[
            const Divider(height: AppSpacing.x20, color: AppColors.n100),
            _row(
              'Остаток к распределению',
              Money.format(payment.remainingToDistribute),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _row(String label, String value) => Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );

  static String _shorten(String userId) {
    if (userId.length <= 8) return userId;
    return '${userId.substring(0, 8)}…';
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.n500,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(child: Text(comment, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x12,
        vertical: AppSpacing.x10,
      ),
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.call_split_rounded,
            color: AppColors.brand,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Money.format(payment.effectiveAmount),
                  style: AppTextStyles.subtitle,
                ),
                Text(
                  payment.status.displayName,
                  style: AppTextStyles.caption.copyWith(
                    color: payment.status.semaphore.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DisputeRow extends StatelessWidget {
  const _DisputeRow({required this.dispute});

  final dynamic dispute; // PaymentDispute — через dynamic чтобы не тянуть import

  @override
  Widget build(BuildContext context) {
    // ignore_for_file: avoid_dynamic_calls
    final reason = dispute.reason as String;
    final status = dispute.status as String;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status == 'resolved' ? 'Спор разрешён' : 'Открытый спор',
            style: AppTextStyles.subtitle.copyWith(color: AppColors.redText),
          ),
          const SizedBox(height: 4),
          Text(reason, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.payment, required this.meId});

  final Payment payment;
  final String? meId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttons = <Widget>[];
    final canConfirm =
        payment.status == PaymentStatus.pending && payment.toUserId == meId;
    final canCancel = payment.status == PaymentStatus.pending &&
        payment.fromUserId == meId;
    final canDispute = payment.status == PaymentStatus.confirmed &&
        (payment.toUserId == meId || payment.fromUserId == meId);
    final canResolve = payment.status == PaymentStatus.disputed;
    final canDistribute = payment.kind == PaymentKind.advance &&
        payment.status == PaymentStatus.confirmed &&
        payment.remainingToDistribute > 0 &&
        payment.toUserId == meId;

    if (canConfirm) {
      buttons.add(
        AppButton(
          label: 'Подтвердить получение',
          variant: AppButtonVariant.success,
          onPressed: () => ref
              .read(paymentsControllerProvider(payment.projectId).notifier)
              .confirm(payment.id),
        ),
      );
    }
    if (canDistribute) {
      buttons
        ..add(const SizedBox(height: AppSpacing.x8))
        ..add(
          AppButton(
            label: 'Распределить мастеру',
            onPressed: () => showDistributeSheet(
              context,
              ref,
              parent: payment,
            ),
          ),
        );
    }
    final isParentAdvance = payment.kind == PaymentKind.advance &&
        payment.parentPaymentId == null &&
        (payment.children.isNotEmpty || payment.toUserId == meId);
    if (isParentAdvance) {
      buttons
        ..add(const SizedBox(height: AppSpacing.x8))
        ..add(
          AppButton(
            label: 'Распределение аванса',
            variant: AppButtonVariant.secondary,
            icon: Icons.account_tree_outlined,
            onPressed: () => context.push(
              '/projects/${payment.projectId}/payments/${payment.id}/distribute',
            ),
          ),
        );
    }
    if (canDispute) {
      buttons
        ..add(const SizedBox(height: AppSpacing.x8))
        ..add(
          AppButton(
            label: 'Открыть спор',
            variant: AppButtonVariant.destructive,
            onPressed: () => showDisputePaymentSheet(
              context,
              ref,
              payment: payment,
            ),
          ),
        );
    }
    if (canResolve) {
      buttons.add(
        AppButton(
          label: 'Разрешить спор',
          onPressed: () => showResolvePaymentSheet(
            context,
            ref,
            payment: payment,
          ),
        ),
      );
    }
    if (canCancel) {
      buttons
        ..add(const SizedBox(height: AppSpacing.x8))
        ..add(
          AppButton(
            label: 'Отменить',
            variant: AppButtonVariant.ghost,
            onPressed: () => ref
                .read(
                  paymentsControllerProvider(payment.projectId).notifier,
                )
                .cancel(payment.id),
          ),
        );
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
}
