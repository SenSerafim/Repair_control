import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/status_pill.dart';
import '../domain/project.dart';

/// Карточка проекта. Соответствует .card из `design/Кластер B — Проекты.html`.
/// Верхняя полоса (card-top ::before) — 3px accentBar по semaphore.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    required this.project,
    this.onTap,
    this.onMenu,
    super.key,
  });

  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.n0,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.n200, width: 1.5),
            boxShadow: AppShadows.sh1,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.card,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 3,
                  color: project.semaphore.dot,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              project.title,
                              style: AppTextStyles.h2,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onMenu != null)
                            GestureDetector(
                              onTap: onMenu,
                              behavior: HitTestBehavior.opaque,
                              child: const Padding(
                                padding: EdgeInsets.all(AppSpacing.x6),
                                child: Icon(
                                  Icons.more_vert_rounded,
                                  color: AppColors.n400,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (project.address != null &&
                          project.address!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.x6),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 14,
                              color: AppColors.n400,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                project.address!,
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.x10),
                      Row(
                        children: [
                          StatusPill(
                            label: project.semaphoreLabel,
                            semaphore: project.semaphore,
                          ),
                          const SizedBox(width: AppSpacing.x8),
                          Expanded(
                            child: Text(
                              _datesLabel(project),
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x8),
                      _ProgressBar(value: project.progressCache / 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _datesLabel(Project p) {
    final df = DateFormat('d MMM', 'ru');
    final start = p.plannedStart == null ? '—' : df.format(p.plannedStart!);
    final end = p.plannedEnd == null ? '—' : df.format(p.plannedEnd!);
    return '$start — $end';
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
