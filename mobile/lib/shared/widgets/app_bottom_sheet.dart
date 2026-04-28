import 'package:flutter/material.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// Обёртка для bottom-sheet'ов (паузы, отклонение, photo-picker и т.д.).
/// Handle 40x4, radius 28, padding 14/20/44, overlay 0.45 + blur 2.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = true,
  bool useRootNavigator = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.overlayBackdrop,
    builder: (_) => _AppBottomSheetBody(child: child),
  );
}

class _AppBottomSheetBody extends StatelessWidget {
  const _AppBottomSheetBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.n0,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.r28),
            topRight: Radius.circular(AppRadius.r28),
          ),
        ),
        padding: AppSpacing.bottomSheet,
        // ConstrainedBox + Column[Flexible] позволяет content'у sheet'а
        // ужиматься без RenderFlex overflow когда содержимое больше экрана
        // (например, длинный invite-form со списком прав).
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.x16),
                decoration: BoxDecoration(
                  color: AppColors.n200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class AppBottomSheetHeader extends StatelessWidget {
  const AppBottomSheetHeader({
    required this.title,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h1),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.x6),
          Text(subtitle!, style: AppTextStyles.bodyMedium),
        ],
        const SizedBox(height: AppSpacing.x16),
      ],
    );
  }
}
