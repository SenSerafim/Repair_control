import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';
import 'status_pill.dart';

/// Баннер на консоли — отображает текущий семафор-статус с CTA.
///
/// Дизайн `Кластер B`: карточка с цветным фоном per semaphore (yellow/red/
/// blue), круглой иконкой слева, заголовком + текстом, опциональной
/// кнопкой-стрелкой справа.
class AppConsoleBanner extends StatelessWidget {
  const AppConsoleBanner({
    required this.semaphore,
    required this.title,
    required this.subtitle,
    this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final Semaphore semaphore;
  final String title;
  final String subtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final iconData = icon ?? _defaultIcon(semaphore);
    final bg = semaphore.bg;
    final fg = semaphore.text;
    final dotColor = semaphore.dot;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: dotColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, size: 18, color: AppColors.n0),
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: fg,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: fg,
                    height: 1.45,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.x8),
                  GestureDetector(
                    onTap: onAction,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: fg,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          PhosphorIconsRegular.arrowRight,
                          size: 12,
                          color: fg,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _defaultIcon(Semaphore s) => switch (s) {
        Semaphore.green => PhosphorIconsFill.checkCircle,
        Semaphore.yellow => PhosphorIconsFill.warning,
        Semaphore.red => PhosphorIconsFill.warningOctagon,
        Semaphore.blue => PhosphorIconsFill.clock,
        _ => PhosphorIconsFill.info,
      };
}
