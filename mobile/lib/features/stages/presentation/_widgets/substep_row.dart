import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../steps/domain/substep.dart';

/// Подшаг — c-stage-done substeps.
///
/// 8×8 dot (brand-light/brand-mid border, или green-mid/green при done) +
/// текст с line-through при done.
class SubstepRow extends StatelessWidget {
  const SubstepRow({
    required this.substep,
    required this.onToggle,
    super.key,
  });

  final Substep substep;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final done = substep.isDone;
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x16,
          vertical: AppSpacing.x10,
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: done ? AppColors.greenDot : AppColors.brandLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? AppColors.greenDark : AppColors.brandMid,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: Text(
                substep.text,
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  color: done ? AppColors.n400 : AppColors.n700,
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
