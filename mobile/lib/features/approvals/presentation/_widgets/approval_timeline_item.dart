import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';

/// Элемент истории согласований — c-stage-approval (timeline).
///
/// Слева 10×10 зелёная точка + 1.5px вертикаль (n200) к следующему элементу.
/// Справа: title (14/700) + byline (11/600 n400) + опц. серый блок-комментарий.
class ApprovalTimelineItem extends StatelessWidget {
  const ApprovalTimelineItem({
    required this.title,
    required this.byline,
    this.comment,
    this.last = false,
    super.key,
  });

  final String title;
  final String byline;
  final String? comment;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 12,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.greenDot,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.glowGreen,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      width: 1.5,
                      color: AppColors.n200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.x12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subtitle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.n800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    byline,
                    style: AppTextStyles.tiny.copyWith(color: AppColors.n400),
                  ),
                  if (comment != null && comment!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.x6),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.x10),
                      decoration: BoxDecoration(
                        color: AppColors.n50,
                        borderRadius: BorderRadius.circular(AppRadius.r8),
                        border: Border.all(color: AppColors.n100),
                      ),
                      child: Text(
                        'Комментарий: «${comment!}»',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.n600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
