import 'package:flutter/material.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/status_pill.dart';
import '../domain/project.dart';

/// Большая traffic-badge для шапки консоли.
class BigTrafficBadge extends StatelessWidget {
  const BigTrafficBadge({required this.semaphore, required this.label, super.key});

  final Semaphore semaphore;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x8,
      ),
      decoration: BoxDecoration(
        color: semaphore.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: semaphore.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          Text(
            label,
            style: AppTextStyles.subtitle.copyWith(
              color: semaphore.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка статистики: Шаги / До дедлайна / Бюджет / ...
class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    this.suffix,
    this.hint,
    this.progress,
    this.progressColor = AppColors.brand,
    super.key,
  });

  final String label;
  final String value;

  /// Меньший текст справа от value (например "/42").
  final String? suffix;
  final String? hint;

  /// 0–1, если null — прогресс-бар не отображается.
  final double? progress;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.screenTitle.copyWith(fontSize: 24),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 2),
                Text(
                  suffix!,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint!, style: AppTextStyles.micro),
          ],
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.x8),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.n100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress!.clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Info-banner над grid'ом — варьируется по semaphore.
class ConsoleBanner extends StatelessWidget {
  const ConsoleBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.n700),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.x8),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      actionLabel!,
                      style: AppTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                      ),
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
}

/// Плитка navigation-grid'а консоли.
class ConsoleNavTile extends StatelessWidget {
  const ConsoleNavTile({
    required this.icon,
    required this.label,
    this.badge,
    this.onTap,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effective = enabled ? onTap : null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: effective,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x12),
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
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.brandLight,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                    child:
                        Icon(icon, size: 18, color: AppColors.brand),
                  ),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      constraints: const BoxConstraints(minWidth: 20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.redDot,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        badge!,
                        style: AppTextStyles.tiny
                            .copyWith(color: AppColors.n0),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.x12),
              Text(
                label,
                style: AppTextStyles.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Короткая карточка этапа в preview-карусели консоли.
class StagePreviewCard extends StatelessWidget {
  const StagePreviewCard({
    required this.index,
    required this.title,
    required this.semaphore,
    required this.progress,
    super.key,
  });

  final int index;
  final String title;
  final Semaphore semaphore;
  final int progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        border: Border.all(color: semaphore.dot.withValues(alpha: 0.3)),
        boxShadow: AppShadows.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: semaphore.bg,
                  borderRadius: BorderRadius.circular(AppRadius.r8),
                ),
                child: Text(
                  '$index',
                  style: AppTextStyles.micro
                      .copyWith(color: semaphore.text),
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(
                  '$progress%',
                  style: AppTextStyles.caption.copyWith(color: semaphore.text),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          Text(
            title,
            style: AppTextStyles.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.x8),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.n100,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (progress / 100).clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(
                  color: semaphore.dot,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension ProjectConsoleX on Project {
  /// Для шапки консоли — адрес + «старт — конец» в одну строку.
  String addressLine() {
    final parts = <String>[
      if (address != null && address!.isNotEmpty) address!,
    ];
    if (plannedStart != null && plannedEnd != null) {
      parts.add(
        '${_fmt(plannedStart!)} — ${_fmt(plannedEnd!)}',
      );
    }
    return parts.join(' · ');
  }
}

String _fmt(DateTime d) {
  const months = [
    'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
