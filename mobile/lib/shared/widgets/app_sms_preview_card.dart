import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';

/// Превью SMS-приглашения для «Подрядчик не найден» (`s-member-not-found`).
///
/// Белая карточка с border, header «SMS на +7 (...)» (синий иконка-чип) и
/// телом сообщения в светло-сером блоке.
class AppSmsPreviewCard extends StatelessWidget {
  const AppSmsPreviewCard({
    required this.phone,
    required this.message,
    super.key,
  });

  final String phone;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.n0,
        border: Border.all(color: AppColors.n200),
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  PhosphorIconsFill.chatCircleText,
                  size: 16,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(
                  'SMS на $phone',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.n700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.x12),
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.n600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
