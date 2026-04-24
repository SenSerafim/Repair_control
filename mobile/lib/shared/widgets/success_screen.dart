import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';
import 'app_button.dart';
import 'app_scaffold.dart';
import 'app_states.dart';

/// s-approved / s-rejected / s-role-switched / s-mat-bought —
/// универсальный «success» экран с AppSuccessBurst + title + subtitle + CTA.
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({
    required this.title,
    this.subtitle,
    this.primaryLabel = 'Готово',
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.isError = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x24,
        AppSpacing.x24,
        AppSpacing.x24,
        AppSpacing.x24,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSuccessBurst(
            color: isError ? AppColors.redDot : AppColors.greenDot,
          ),
          const SizedBox(height: AppSpacing.x20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h1,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.x8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.n500),
            ),
          ],
          const SizedBox(height: AppSpacing.x24),
          AppButton(
            label: primaryLabel,
            onPressed: onPrimary ?? () => context.pop(),
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: AppSpacing.x8),
            AppButton(
              label: secondaryLabel!,
              variant: AppButtonVariant.ghost,
              onPressed: onSecondary ?? () => context.pop(),
            ),
          ],
        ],
      ),
    );
  }
}
