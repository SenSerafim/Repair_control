import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/tool.dart';

/// Compact row для списка инструментов / выдач (e-instruments):
/// icon-bg + name + meta (С/Н, локация, человек) + status-pill.
class ToolRow extends StatelessWidget {
  const ToolRow({
    required this.title,
    required this.meta,
    required this.statusLabel,
    required this.semaphore,
    this.onTap,
    this.icon = Icons.construction_outlined,
    super.key,
  });

  /// Удобный конструктор из ToolIssuance.
  factory ToolRow.fromIssuance({
    required ToolIssuance issuance,
    required String recipientName,
    VoidCallback? onTap,
  }) {
    final tool = issuance.tool?.name ?? 'Инструмент';
    final qty = issuance.qty;
    final locationParts = [
      if (issuance.tool?.unit != null) issuance.tool!.unit!,
      'Кол-во: $qty',
      recipientName,
    ];
    return ToolRow(
      title: tool,
      meta: locationParts.join(' · '),
      statusLabel: issuance.status.displayName,
      semaphore: issuance.status.semaphore,
      onTap: onTap,
    );
  }

  /// Конструктор из ToolItem (для warehouse-режима).
  factory ToolRow.fromItem({
    required ToolItem item,
    VoidCallback? onTap,
  }) {
    return ToolRow(
      title: item.name,
      meta: 'Свободно: ${item.availableQty}/${item.totalQty}',
      statusLabel: 'На складе',
      semaphore: Semaphore.green,
      onTap: onTap,
    );
  }

  final String title;
  final String meta;
  final String statusLabel;
  final Semaphore semaphore;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.card,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x16,
          vertical: AppSpacing.x14,
        ),
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.n200),
          boxShadow: AppShadows.sh1,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.n100,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(icon, size: 20, color: AppColors.n600),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.n800,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.n400,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: semaphore.bg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                statusLabel,
                style: AppTextStyles.tiny.copyWith(
                  color: semaphore.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
