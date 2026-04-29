import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/stage.dart';
import '../stage_widgets.dart' show StageDisplayStatus;

/// Карточка этапа в плиточном виде — c-stages-tile.
///
/// 14px padding, top 3px stripe (gradient или solid по статусу), eyebrow
/// «Этап N», title, StatusPill, ряд meta-rows и тонкий 4px progress bar
/// внизу.
class StageStripeCard extends StatelessWidget {
  const StageStripeCard({
    required this.stage,
    required this.display,
    required this.orderIndex,
    required this.onTap,
    this.foremanName,
    this.stepsDone = 0,
    this.stepsTotal = 0,
    this.questionsCount = 0,
    super.key,
  });

  final Stage stage;
  final StageDisplayStatus display;
  final int orderIndex;
  final VoidCallback onTap;

  /// Имя бригадира для отображения. Если null/пусто — рендерим «Не назначен».
  final String? foremanName;
  final int stepsDone;
  final int stepsTotal;
  final int questionsCount;

  @override
  Widget build(BuildContext context) {
    final progress = (stage.progressCache / 100).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: display.semaphore.dot.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: AppShadows.sh1,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top stripe
              Container(height: 3, color: display.semaphore.dot),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Этап $orderIndex',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.n400,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      stage.title,
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.n900,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.x6),
                    StatusPill(
                      label: display.displayName,
                      semaphore: display.semaphore,
                    ),
                    const SizedBox(height: AppSpacing.x8),
                    _MetaRow(
                      icon: Icons.person_outline,
                      label: foremanName == null || foremanName!.isEmpty
                          ? 'Не назначен'
                          : foremanName!,
                      colorOverride:
                          (foremanName == null || foremanName!.isEmpty)
                              ? AppColors.redDot
                              : null,
                    ),
                    _MetaRow(
                      icon: Icons.check_box_outlined,
                      label: '$stepsDone/$stepsTotal шагов',
                    ),
                    _MetaRow(
                      icon: Icons.help_outline_rounded,
                      label: questionsCount == 0
                          ? 'Вопросов нет'
                          : '$questionsCount вопроса',
                      colorOverride:
                          questionsCount > 0 ? AppColors.yellowText : null,
                    ),
                    _MetaRow(
                      icon: Icons.calendar_today_outlined,
                      label: _deadlineLabel(stage),
                      colorOverride: _deadlineColor(),
                    ),
                    const SizedBox(height: AppSpacing.x8),
                    // 4px progress bar
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.n100,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: display.semaphore.dot,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color? _deadlineColor() {
    return switch (display) {
      StageDisplayStatus.done => AppColors.greenDark,
      StageDisplayStatus.overdue => AppColors.redDot,
      StageDisplayStatus.lateStart => AppColors.redDot,
      StageDisplayStatus.paused => AppColors.redDot,
      StageDisplayStatus.active => AppColors.greenDark,
      _ => null,
    };
  }

  String _deadlineLabel(Stage s) {
    final df = DateFormat('d MMM', 'ru');
    if (display == StageDisplayStatus.done && s.doneAt != null) {
      return 'В срок · ${df.format(s.doneAt!)}';
    }
    if (display == StageDisplayStatus.paused) {
      return s.plannedEnd == null
          ? 'На паузе'
          : 'Дедлайн: ${df.format(s.plannedEnd!)} (сдвинут)';
    }
    if (display == StageDisplayStatus.overdue && s.plannedEnd != null) {
      final days = DateTime.now().difference(s.plannedEnd!).inDays;
      return 'Просрочен на $days д';
    }
    if (display == StageDisplayStatus.pending && s.plannedStart != null) {
      return 'Старт: ${df.format(s.plannedStart!)}';
    }
    if (display == StageDisplayStatus.active && s.plannedEnd != null) {
      return 'По графику · ${df.format(s.plannedEnd!)}';
    }
    if (s.plannedEnd != null) return 'Дедлайн: ${df.format(s.plannedEnd!)}';
    return 'Сроки не заданы';
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    this.colorOverride,
  });

  final IconData icon;
  final String label;
  final Color? colorOverride;

  @override
  Widget build(BuildContext context) {
    final color = colorOverride ?? AppColors.n400;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
