import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/money.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/material_request.dart';

/// Карточка заявки в списке материалов (e-materials):
/// иконка-bg по статусу + title + meta + status-badge + сумма.
class MaterialCard extends StatelessWidget {
  const MaterialCard({
    required this.request,
    required this.onTap,
    super.key,
  });

  final MaterialRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semaphore = request.status.semaphore;
    final iconBg = semaphore.bg;
    final iconColor = semaphore.text;
    final amount = request.totalBoughtPrice;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.card,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200),
          boxShadow: AppShadows.sh1,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.n900,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${request.recipient.displayName} · '
                          '${request.items.length} поз.',
                          style: AppTextStyles.tiny.copyWith(
                            color: AppColors.n400,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.n100)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      request.status.displayName,
                      style: AppTextStyles.tiny.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    Money.format(amount),
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.n800,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
