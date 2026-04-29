import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/stage.dart';
import '../stage_widgets.dart' show StageDisplayStatus;

/// Карточка этапа в list-view — c-stages-list.
///
/// 4×40 vertical color bar слева, title + subtitle (status · contractor · X/Y),
/// percent справа, опц. drag-grip.
class StageRowCard extends StatelessWidget {
  const StageRowCard({
    required this.stage,
    required this.display,
    required this.onTap,
    this.foremanName,
    this.stepsDone = 0,
    this.stepsTotal = 0,
    this.reorderable = false,
    super.key,
  });

  final Stage stage;
  final StageDisplayStatus display;
  final VoidCallback onTap;
  final String? foremanName;
  final int stepsDone;
  final int stepsTotal;
  final bool reorderable;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.n0,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.n200),
            boxShadow: AppShadows.sh1,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: display.semaphore.dot,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.title,
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.n900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.x6,
                      children: [
                        StatusPill(
                          label: display.displayName,
                          semaphore: display.semaphore,
                          showDot: false,
                        ),
                        Text(
                          '·',
                          style: AppTextStyles.tiny.copyWith(
                            color: AppColors.n300,
                          ),
                        ),
                        Text(
                          foremanName == null || foremanName!.isEmpty
                              ? 'Не назначен'
                              : foremanName!,
                          style: AppTextStyles.tiny.copyWith(
                            color: foremanName == null || foremanName!.isEmpty
                                ? AppColors.redDot
                                : AppColors.n500,
                          ),
                        ),
                        Text(
                          '·',
                          style: AppTextStyles.tiny.copyWith(
                            color: AppColors.n300,
                          ),
                        ),
                        Text(
                          '$stepsDone/$stepsTotal',
                          style: AppTextStyles.tiny.copyWith(
                            color: AppColors.n500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x10),
              Text(
                '${stage.progressCache}%',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: display.semaphore.text,
                  letterSpacing: -0.5,
                ),
              ),
              if (reorderable) ...[
                const SizedBox(width: AppSpacing.x6),
                const Icon(
                  Icons.drag_indicator_rounded,
                  size: 18,
                  color: AppColors.n300,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
