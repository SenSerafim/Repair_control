import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/access/access_guard.dart';
import '../../../core/access/domain_actions.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../application/payments_controller.dart';
import '../domain/payment.dart';
import '../domain/payment_policy.dart';
import '_widgets/payment_amount_hero.dart';
import '_widgets/payment_info_card.dart';
import 'payment_sheets.dart';

/// e-pay-pending / e-pay-confirmed / e-pay-disputed — унифицированный экран
/// детали выплаты. Layout: status-pill в header, centered amount-hero, dl-rows
/// info-card, опциональная dispute-banner, distribution-section, action-bar.
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
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x16,
                    AppSpacing.x10,
                    AppSpacing.x16,
                    AppSpacing.x20,
                  ),
                  children: [
                    // Top status-pill (в дизайне — справа в header).
                    Center(
                      child: StatusPill(
                        label: p.status.displayName,
                        semaphore: p.status.semaphore,
                      ),
                    ),
                    PaymentAmountHero(payment: p),
                    if (p.status == PaymentStatus.disputed &&
                        p.disputes.isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.x12),
                        child: _DisputeBanner(dispute: p.disputes.first),
                      ),
                    PaymentInfoCard(rows: _infoRows(p)),
                    if (p.parentPaymentId != null) ...[
                      const SizedBox(height: AppSpacing.x12),
                      _ParentLink(parentId: p.parentPaymentId!),
                    ],
                    if (p.comment != null && p.comment!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.x12),
                      _CommentCard(comment: p.comment!),
                    ],
                    if (p.activeChildren.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.x16),
                      _DistributionHeader(parent: p),
                      const SizedBox(height: AppSpacing.x8),
                      for (final c in p.activeChildren) ...[
                        _ChildRow(payment: c),
                        const SizedBox(height: AppSpacing.x6),
                      ],
                    ],
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

  List<PaymentInfoRow> _infoRows(Payment p) {
    final fmt = DateFormat('d MMMM y · HH:mm', 'ru');
    return [
      PaymentInfoRow('Получатель', _shorten(p.toUserId)),
      PaymentInfoRow('Этап', p.stageId == null ? 'Без этапа' : _shorten(p.stageId!)),
      PaymentInfoRow('Тип', p.kind.displayName),
      PaymentInfoRow(
        'Дата отправки',
        fmt.format(p.createdAt),
      ),
      if (p.confirmedAt != null)
        PaymentInfoRow(
          'Подтверждена',
          '${fmt.format(p.confirmedAt!)} (неизменяемая)',
          valueColor: AppColors.greenDark,
        ),
      PaymentInfoRow(
        'Статус',
        p.status.displayName,
        valueColor: p.status.semaphore.text,
      ),
      if (p.children.isNotEmpty)
        PaymentInfoRow(
          'Остаток к распределению',
          Money.format(p.remainingToDistribute),
        ),
    ];
  }

  String _shorten(String id) =>
      id.length <= 12 ? id : '${id.substring(0, 12)}…';
}

class _DisputeBanner extends StatelessWidget {
  const _DisputeBanner({required this.dispute});

  final PaymentDispute dispute;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        border: Border.all(color: AppColors.redDot.withValues(alpha: 0.3)),
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Причина',
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.redText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dispute.reason,
            style: AppTextStyles.body.copyWith(
              color: AppColors.redText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Открыл: ${_shorten(dispute.openedById)} · '
            '${DateFormat('dd.MM.yyyy').format(dispute.createdAt)}',
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.redText.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _shorten(String id) =>
      id.length <= 12 ? id : '${id.substring(0, 12)}…';
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
    return GestureDetector(
      onTap: () => context.push(AppRoutes.paymentDetailWith(payment.id)),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: AppColors.n0,
          border: Border.all(color: AppColors.n200),
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          children: [
            AppAvatar(seed: payment.toUserId, size: 36),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Money.format(payment.effectiveAmount),
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 2),
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
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.n300,
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentLink extends StatelessWidget {
  const _ParentLink({required this.parentId});

  final String parentId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.paymentDetailWith(parentId)),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x12),
        decoration: BoxDecoration(
          color: AppColors.brandLight,
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.account_tree_outlined,
              color: AppColors.brand,
              size: 20,
            ),
            SizedBox(width: AppSpacing.x10),
            Expanded(
              child: Text(
                'Из аванса бригадира',
                style: AppTextStyles.subtitle,
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.brand),
          ],
        ),
      ),
    );
  }
}

class _DistributionHeader extends StatelessWidget {
  const _DistributionHeader({required this.parent});

  final Payment parent;

  @override
  Widget build(BuildContext context) {
    final remaining = parent.remainingToDistribute;
    final overspent = remaining < 0;
    return Row(
      children: [
        const Expanded(
          child: Text('Распределение', style: AppTextStyles.h2),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: overspent ? AppColors.redBg : AppColors.brandLight,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            overspent
                ? 'Превышение ${Money.format(-remaining)}'
                : 'Остаток ${Money.format(remaining)}',
            style: AppTextStyles.caption.copyWith(
              color: overspent ? AppColors.redDot : AppColors.brand,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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
    final hasConfirm = ref.watch(canInProjectProvider(
      (
        action: DomainAction.financePaymentConfirm,
        projectId: payment.projectId,
      ),
    ));
    final hasCreate = ref.watch(canInProjectProvider(
      (
        action: DomainAction.financePaymentCreate,
        projectId: payment.projectId,
      ),
    ));
    final hasDispute = ref.watch(canInProjectProvider(
      (
        action: DomainAction.financePaymentDispute,
        projectId: payment.projectId,
      ),
    ));
    final hasResolve = ref.watch(canInProjectProvider(
      (
        action: DomainAction.financePaymentResolve,
        projectId: payment.projectId,
      ),
    ));

    // Все вычисления допустимости вынесены в PaymentPolicy — единая точка
    // истины. См. таблицу матрицы прав в payment_policy.dart.
    final canConfirm = PaymentPolicy.canConfirm(
      payment: payment,
      meId: meId,
      hasConfirm: hasConfirm,
    );
    final canCancel = PaymentPolicy.canCancel(payment: payment, meId: meId);
    final canDispute = PaymentPolicy.canDispute(
      payment: payment,
      meId: meId,
      hasDispute: hasDispute,
    );
    final canResolve = PaymentPolicy.canResolve(
      payment: payment,
      hasResolve: hasResolve,
    );
    final canDistribute = PaymentPolicy.canDistribute(
      payment: payment,
      meId: meId,
      hasCreate: hasCreate,
    );
    final canViewDistribution = PaymentPolicy.canViewDistribution(
      payment: payment,
      meId: meId,
    );

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
    if (canViewDistribution) {
      buttons
        ..add(const SizedBox(height: AppSpacing.x8))
        ..add(
          AppButton(
            label: 'Распределение аванса',
            variant: AppButtonVariant.secondary,
            icon: Icons.account_tree_outlined,
            // Bottom sheet вместо push — go_router 14 при пуше поверх
            // PaymentDetailScreen ловил `!keyReservation.contains(key)` →
            // `_debugLocked`, и Navigator залипал так, что back не работал.
            onPressed: () => showAdvanceDistributionSheet(
              context,
              parent: payment,
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
                .read(paymentsControllerProvider(payment.projectId).notifier)
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
