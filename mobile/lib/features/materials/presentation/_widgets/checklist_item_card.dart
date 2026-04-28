import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/money.dart';
import '../../domain/material_request.dart';

/// Состояние позиции в чеклисте закупки.
enum ChecklistItemState {
  pending, // ещё не куплено
  partial, // куплено частично
  bought, // куплено полностью
}

/// Карточка позиции в e-mat-checklist:
/// [круглый чекбокс] [название + meta] [edit-icon + delete-icon] [status-pill].
class ChecklistItemCard extends StatelessWidget {
  const ChecklistItemCard({
    required this.item,
    required this.state,
    this.onToggle,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final MaterialItem item;
  final ChecklistItemState state;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.n200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: _Checkbox(state: state),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.n800,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onEdit != null)
                      _IconButton(
                        icon: Icons.edit_outlined,
                        color: AppColors.n400,
                        onTap: onEdit!,
                      ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 4),
                      _IconButton(
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.redDot,
                        onTap: onDelete!,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _meta(),
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.n500,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                _StatusBadge(state: state, boughtAt: item.boughtAt),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _meta() {
    final qty = item.qty == item.qty.truncateToDouble()
        ? item.qty.toInt().toString()
        : item.qty.toStringAsFixed(2);
    final unit = item.unit ?? '';
    final price = item.pricePerUnit == null
        ? ''
        : ' · ${Money.format(item.pricePerUnit!)}/$unit';
    final total = item.totalPrice == null
        ? ''
        : ' · ${Money.format(item.totalPrice!)}';
    return '$qty $unit$price$total';
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.state});

  final ChecklistItemState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: state == ChecklistItemState.pending
            ? Colors.transparent
            : AppColors.greenDot,
        border: state == ChecklistItemState.pending
            ? Border.all(color: AppColors.n300, width: 2)
            : null,
        boxShadow: state == ChecklistItemState.pending
            ? null
            : AppShadows.glowGreen,
      ),
      child: state == ChecklistItemState.pending
          ? null
          : const Icon(
              Icons.check_rounded,
              size: 14,
              color: AppColors.n0,
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state, required this.boughtAt});

  final ChecklistItemState state;
  final DateTime? boughtAt;

  @override
  Widget build(BuildContext context) {
    final (label, bg, color) = switch (state) {
      ChecklistItemState.bought =>
        ('Куплено', AppColors.greenLight, AppColors.greenDark),
      ChecklistItemState.partial =>
        ('Частично', AppColors.yellowBg, AppColors.yellowText),
      ChecklistItemState.pending =>
        ('Ожидает', AppColors.n100, AppColors.n500),
    };
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.r8),
          ),
          child: Text(
            label,
            style: AppTextStyles.tiny.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ),
        if (boughtAt != null) ...[
          const SizedBox(width: 6),
          Text(
            _fmt(boughtAt!),
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.n400,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    const months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'мая',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    return '$dd ${months[d.month - 1]} · '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
