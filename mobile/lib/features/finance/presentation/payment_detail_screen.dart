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
import '../../projects/domain/membership.dart';
import '../../stages/application/stages_controller.dart';
import '../../stages/domain/stage.dart';
import '../../team/application/team_controller.dart';
import '../application/payments_controller.dart';
import '../domain/payment.dart';
import '../domain/payment_policy.dart';
import '_widgets/payment_amount_hero.dart';
import '_widgets/payment_info_card.dart';
import 'payment_sheets.dart';

/// Унифицированный экран детали выплаты. В упрощённой модели (2026-05-12)
/// платёж = факт передачи денег: нет статусов, нет подтверждений/споров.
/// Layout: centered amount-hero → info-card → optional parent-link / comment /
/// distribution-section → action-bar (только distribute для бригадира-получателя).
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
        data: (p) {
          // Получатель и этап в API — это сырые id. Резолвим в читаемые имена
          // через команду проекта и список этапов (Егор 23.06.2026).
          final team = ref.watch(teamControllerProvider(p.projectId)).value;
          final recipientName = _resolveRecipient(team?.members, p.toUserId);
          final stages = ref.watch(stagesControllerProvider(p.projectId)).value;
          final stageLabel = _resolveStageLabel(stages, p.stageId);
          return Column(
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
                      PaymentAmountHero(payment: p),
                      PaymentInfoCard(
                        rows: _infoRows(p, recipientName, stageLabel),
                      ),
                      if (p.parentPaymentId != null) ...[
                        const SizedBox(height: AppSpacing.x12),
                        _ParentLink(parentId: p.parentPaymentId!),
                      ],
                      if (p.comment != null && p.comment!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.x12),
                        _CommentCard(comment: p.comment!),
                      ],
                      if (p.children.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.x16),
                        _DistributionHeader(parent: p),
                        const SizedBox(height: AppSpacing.x8),
                        for (final c in p.children) ...[
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
          );
        },
      ),
    );
  }

  List<PaymentInfoRow> _infoRows(
    Payment p,
    String recipientName,
    String stageLabel,
  ) {
    final fmt = DateFormat('d MMMM y · HH:mm', 'ru');
    return [
      PaymentInfoRow('Получатель', recipientName),
      PaymentInfoRow('Этап', stageLabel),
      PaymentInfoRow('Тип', p.kind.displayName),
      PaymentInfoRow('Дата отправки', fmt.format(p.createdAt.toLocal())),
      if (p.children.isNotEmpty)
        PaymentInfoRow(
          'Остаток к распределению',
          Money.format(p.remainingToDistribute),
        ),
    ];
  }
}

/// Имя получателя из команды проекта: «Имя Фамилия». Если участник не найден
/// (удалён / команда ещё грузится) — укороченный id как безопасный fallback.
String _resolveRecipient(List<Membership>? members, String userId) {
  if (members != null) {
    for (final m in members) {
      if (m.userId == userId) {
        final u = m.user;
        if (u != null) {
          final full = '${u.firstName} ${u.lastName}'.trim();
          if (full.isNotEmpty) return full;
        }
        break;
      }
    }
  }
  return userId.length <= 12 ? userId : '${userId.substring(0, 12)}…';
}

/// Подпись этапа: «Этап N: Название». null → «Без этапа», не найден → id.
String _resolveStageLabel(List<Stage>? stages, String? stageId) {
  if (stageId == null) return 'Без этапа';
  if (stages != null) {
    for (final s in stages) {
      if (s.id == stageId) {
        return s.title.trim().isNotEmpty
            ? 'Этап ${s.orderIndex + 1}: ${s.title}'
            : 'Этап ${s.orderIndex + 1}';
      }
    }
  }
  return stageId.length <= 12 ? stageId : '${stageId.substring(0, 12)}…';
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
          boxShadow: AppShadows.shCard,
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
                    Money.format(payment.amount),
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    payment.kind.displayName,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.n500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.n300),
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF1F4FE), AppColors.brandLight],
          ),
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(color: AppColors.brand.withValues(alpha: 0.18)),
        ),
        child: const Row(
          children: [
            Icon(Icons.account_tree_outlined, color: AppColors.brand, size: 20),
            SizedBox(width: AppSpacing.x10),
            Expanded(
              child: Text('Из аванса бригадира', style: AppTextStyles.subtitle),
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
        const Expanded(child: Text('Распределение', style: AppTextStyles.h2)),
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
    // В упрощённой модели единственное действие на детали платежа для
    // бригадира-получателя — распределить полученный аванс мастеру.
    final hasDistribute = ref.watch(
      canInProjectProvider((
        action: DomainAction.financePaymentDistribute,
        projectId: payment.projectId,
      )),
    );
    final canDistribute = PaymentPolicy.canDistribute(
      payment: payment,
      meId: meId,
      hasDistribute: hasDistribute,
    );
    final canViewDistribution = PaymentPolicy.canViewDistribution(
      payment: payment,
      meId: meId,
    );

    if (canDistribute) {
      buttons.add(
        AppButton(
          label: 'Распределить мастеру',
          onPressed: () => showDistributeSheet(context, ref, parent: payment),
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
            // PaymentDetailScreen ловил `!keyReservation.contains(key)`
            // и Navigator залипал.
            onPressed: () =>
                showAdvanceDistributionSheet(context, parent: payment),
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
