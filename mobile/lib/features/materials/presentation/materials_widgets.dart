import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/utils/money.dart';
import '../../../shared/widgets/status_pill.dart';
import '../domain/material_request.dart';

class MaterialRequestCard extends StatelessWidget {
  const MaterialRequestCard({
    required this.request,
    required this.onTap,
    super.key,
  });

  final MaterialRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x14),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200, width: 1.5),
          boxShadow: AppShadows.sh1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.title,
                    style: AppTextStyles.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (request.items.isNotEmpty)
                  Text(
                    '${request.boughtItemsCount}/${request.items.length}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.brand),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                StatusPill(
                  label: request.status.displayName,
                  semaphore: request.status.semaphore,
                ),
                const SizedBox(width: AppSpacing.x8),
                Text(
                  request.recipient.displayName,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            if (request.totalBoughtPrice > 0) ...[
              const SizedBox(height: AppSpacing.x6),
              Text(
                'Куплено на ${Money.format(request.totalBoughtPrice)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMM HH:mm', 'ru').format(request.createdAt),
              style: AppTextStyles.tiny,
            ),
          ],
        ),
      ),
    );
  }
}
