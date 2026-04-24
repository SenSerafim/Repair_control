import 'package:flutter/material.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../application/projects_list_controller.dart';

/// Горизонтальный скролл фильтров — соответствует .filter-bar из design.
class ProjectsFilterChips extends StatelessWidget {
  const ProjectsFilterChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ProjectsFilter selected;
  final ValueChanged<ProjectsFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
        itemCount: ProjectsFilter.values.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppSpacing.x8),
        itemBuilder: (_, i) {
          final filter = ProjectsFilter.values[i];
          final isActive = filter == selected;
          return GestureDetector(
            onTap: () => onSelected(filter),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x14,
                vertical: AppSpacing.x6,
              ),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [AppColors.brand, AppColors.brandDark],
                      )
                    : null,
                color: isActive ? null : AppColors.n100,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: isActive ? AppShadows.shBlue : null,
              ),
              child: Center(
                child: Text(
                  filter.label,
                  style: AppTextStyles.caption.copyWith(
                    color: isActive ? AppColors.n0 : AppColors.n600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
