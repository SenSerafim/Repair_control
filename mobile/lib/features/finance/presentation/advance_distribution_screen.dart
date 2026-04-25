import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/widgets.dart';
import '../../projects/domain/membership.dart';
import '../../team/application/team_controller.dart';
import '../data/payments_repository.dart';
import '../domain/payment.dart';

/// e-advance — экран распределения аванса бригадиром.
/// Показывает: сумму аванса, распределено/остаток, список
/// детей-выплат мастерам, кнопку добавить выплату.
class AdvanceDistributionScreen extends ConsumerWidget {
  const AdvanceDistributionScreen({
    required this.projectId,
    required this.paymentId,
    super.key,
  });

  final String projectId;
  final String paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_paymentProvider(paymentId));
    final team = ref.watch(teamControllerProvider(projectId));

    return AppScaffold(
      showBack: true,
      title: 'Распределение аванса',
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const AppLoadingState(),
        error: (e, _) => AppErrorState(
          title: 'Не удалось загрузить',
          onRetry: () => ref.invalidate(_paymentProvider(paymentId)),
        ),
        data: (p) {
          Membership? findMember(String uid) {
            final members = team.valueOrNull?.members ?? const <Membership>[];
            for (final m in members) {
              if (m.userId == uid) return m;
            }
            return null;
          }

          return _View(
            payment: p,
            projectId: projectId,
            memberLookup: findMember,
          );
        },
      ),
    );
  }
}

final _paymentProvider =
    FutureProvider.autoDispose.family<Payment, String>((ref, id) async {
  return ref.read(paymentsRepositoryProvider).get(id);
});

class _View extends StatelessWidget {
  const _View({
    required this.payment,
    required this.projectId,
    required this.memberLookup,
  });

  final Payment payment;
  final String projectId;
  final Membership? Function(String userId) memberLookup;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x16,
        AppSpacing.x16,
        AppSpacing.x24,
      ),
      children: [
        _SummaryCard(payment: payment),
        const SizedBox(height: AppSpacing.x16),
        Text(
          'Распределено мастерам',
          style: AppTextStyles.micro.copyWith(color: AppColors.n400),
        ),
        const SizedBox(height: AppSpacing.x8),
        if (payment.children.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.x16),
            decoration: BoxDecoration(
              color: AppColors.n0,
              border: Border.all(color: AppColors.n200),
              borderRadius: BorderRadius.circular(AppRadius.r16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 28,
                  color: AppColors.n400,
                ),
                const SizedBox(height: AppSpacing.x8),
                Text(
                  'Нет выплат',
                  style: AppTextStyles.subtitle.copyWith(color: AppColors.n500),
                ),
              ],
            ),
          )
        else
          for (final c in payment.children) ...[
            _ChildRow(
              child: c,
              member: memberLookup(c.toUserId),
              onTap: () => context.push(AppRoutes.paymentDetailWith(c.id)),
            ),
            const SizedBox(height: AppSpacing.x8),
          ],
        const SizedBox(height: AppSpacing.x8),
        Container(
          padding: const EdgeInsets.all(AppSpacing.x12),
          decoration: BoxDecoration(
            color: AppColors.yellowBg,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.yellowText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Заказчик не видит распределение — это внутренняя кухня '
                  'бригадира.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.yellowText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        AppButton(
          label: 'Выплатить мастеру',
          icon: Icons.add_rounded,
          onPressed: () =>
              context.push('/projects/$projectId/payments/advance'),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        border: Border.all(color: AppColors.greenDot.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Получено от заказчика',
            style: AppTextStyles.micro.copyWith(
              color: AppColors.greenDark,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            Money.format(payment.effectiveAmount),
            style: AppTextStyles.h1.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.greenDark,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Распределено: ${Money.format(payment.distributedAmount)} · '
            'Остаток: ${Money.format(payment.remainingToDistribute)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.greenDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x12,
              vertical: AppSpacing.x6,
            ),
            decoration: BoxDecoration(
              color: AppColors.yellowBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '⚠ Превышение остатка — предупреждение, не блок.',
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.yellowText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({
    required this.child,
    required this.member,
    required this.onTap,
  });

  final Payment child;
  final Membership? member;
  final VoidCallback onTap;

  String _name(Membership? m) {
    if (m?.user == null) return 'Мастер';
    return '${m!.user!.firstName} ${m.user!.lastName}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x16,
          vertical: AppSpacing.x14,
        ),
        decoration: BoxDecoration(
          color: AppColors.n0,
          border: Border.all(color: AppColors.n200),
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: AppShadows.sh1,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name(member),
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    child.status.displayName,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.n500),
                  ),
                ],
              ),
            ),
            Text(
              Money.format(child.effectiveAmount),
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.n900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
