import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/money.dart';
import '../../domain/money_flow.dart';

/// «Касса бригадира» — заметная hero-карточка на BudgetScreen для роли foreman.
/// Показывает агрегированный остаток для распределения мастерам:
///   advancesReceived − distributed = available.
///
/// `available` может быть отрицательным (бригадир распределил мастерам больше,
/// чем получил от заказчика) — это OK по ТЗ §4.2. В таком случае цвета
/// переключаются на красные, но число выводится как есть (без clamp).
class ForemanWalletCard extends StatelessWidget {
  const ForemanWalletCard({required this.wallet, super.key});

  final ForemanWallet wallet;

  @override
  Widget build(BuildContext context) {
    final isNegative = wallet.available < 0;
    final accent = isNegative ? AppColors.redText : AppColors.brand;
    final accentBg = isNegative
        ? AppColors.redBg
        : AppColors.brandLight;
    final accentBorder = isNegative
        ? AppColors.redDot
        : AppColors.brand;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: accentBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: accentBorder.withValues(alpha: 0.35)),
        boxShadow: AppShadows.shCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.n0,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 20,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.x10),
              Expanded(
                child: Text(
                  'МОЯ КАССА',
                  style: AppTextStyles.tiny.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          Text(
            Money.format(wallet.available),
            style: AppTextStyles.screenTitle.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: accent,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isNegative
                ? 'Распределено мастерам больше, чем получено от заказчика'
                : 'Доступно для распределения мастерам',
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.n600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          Row(
            children: [
              Expanded(
                child: _LedgerRow(
                  label: 'Получено',
                  amount: wallet.advancesReceived,
                  icon: Icons.south_west_rounded,
                  color: AppColors.greenDark,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: AppColors.n200,
              ),
              Expanded(
                child: _LedgerRow(
                  label: 'Распределено',
                  amount: wallet.distributed,
                  icon: Icons.north_east_rounded,
                  color: AppColors.n700,
                  rightAligned: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.rightAligned = false,
  });

  final String label;
  final int amount;
  final IconData icon;
  final Color color;
  final bool rightAligned;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: rightAligned ? AppSpacing.x10 : 0,
        right: rightAligned ? 0 : AppSpacing.x10,
      ),
      child: Column(
        crossAxisAlignment:
            rightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: rightAligned
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.tiny.copyWith(
                  color: AppColors.n500,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            Money.format(amount),
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.n900,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
