import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/money.dart';

/// 3-колоночная таблица материалов в бюджете (e-budget-materials):
/// [Материал] [Кол-во] [Сумма], header в n50, footer-итого.
class BudgetMaterialsTable extends StatelessWidget {
  const BudgetMaterialsTable({
    required this.rows,
    super.key,
  });

  final List<BudgetMaterialsRow> rows;

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<int>(0, (acc, r) => acc + r.amount);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _Header(),
          for (var i = 0; i < rows.length; i++) ...[
            _Row(row: rows[i]),
            if (i < rows.length - 1)
              const Divider(height: 1, color: AppColors.n100),
          ],
          _Footer(count: rows.length, total: total),
        ],
      ),
    );
  }
}

class BudgetMaterialsRow {
  const BudgetMaterialsRow({
    required this.title,
    required this.subtitle,
    required this.qtyLabel,
    required this.amount,
    this.highlight = false,
  });

  final String title;
  final String subtitle;
  final String qtyLabel;
  final int amount;

  /// true — для самозакупов (название brand-цвета).
  final bool highlight;
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.n50,
        border: Border(bottom: BorderSide(color: AppColors.n200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'МАТЕРИАЛ',
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.n400,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              'КОЛ-ВО',
              textAlign: TextAlign.center,
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.n400,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              'СУММА',
              textAlign: TextAlign.right,
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.n400,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row});

  final BudgetMaterialsRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: AppTextStyles.subtitle.copyWith(
                    color: row.highlight ? AppColors.brand : AppColors.n800,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  row.subtitle,
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.n400,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              row.qtyLabel,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.n700,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              Money.format(row.amount),
              textAlign: TextAlign.right,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.n900,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.count, required this.total});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.n50,
        border: Border(top: BorderSide(color: AppColors.n200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Итого · $count ${_pluralPositions(count)}',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.n800,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            Money.format(total),
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.n900,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _pluralPositions(int n) {
    if (n == 1) return 'позиция';
    if (n >= 2 && n <= 4) return 'позиции';
    return 'позиций';
  }
}
