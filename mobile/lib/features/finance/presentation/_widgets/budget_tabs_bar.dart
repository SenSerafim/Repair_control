import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';

/// 3 таба бюджета: Выплаты (с числовым badge) / По этапам / Материалы.
/// Без анимаций — selected = brand-colored bottom border + brand text.
enum BudgetTab { payments, stages, materials }

class BudgetTabsBar extends StatelessWidget {
  const BudgetTabsBar({
    required this.selected,
    required this.onChanged,
    required this.paymentsCount,
    super.key,
  });

  final BudgetTab selected;
  final ValueChanged<BudgetTab> onChanged;
  final int paymentsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.n0,
        border: Border(bottom: BorderSide(color: AppColors.n200)),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Выплаты',
            badge: paymentsCount > 0 ? '$paymentsCount' : null,
            active: selected == BudgetTab.payments,
            onTap: () => onChanged(BudgetTab.payments),
          ),
          _Tab(
            label: 'По этапам',
            active: selected == BudgetTab.stages,
            onTap: () => onChanged(BudgetTab.stages),
          ),
          _Tab(
            label: 'Материалы',
            active: selected == BudgetTab.materials,
            onTap: () => onChanged(BudgetTab.materials),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.brand : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.subtitle.copyWith(
                  color: active ? AppColors.brand : AppColors.n400,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 5),
                Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    badge!,
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
