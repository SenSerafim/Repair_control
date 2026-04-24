import 'package:flutter/material.dart';

import '../../../core/access/system_role.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';

/// Карточка выбора роли. Как role-card из макета s-roles.
class RoleCard extends StatelessWidget {
  const RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final SystemRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(role);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(AppSpacing.x16),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLight : AppColors.n0,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.n200,
            width: 1.5,
          ),
          boxShadow: selected ? AppShadows.shBlue : AppShadows.sh1,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.brand : AppColors.brandLight,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(
                meta.icon,
                size: 22,
                color: selected ? AppColors.n0 : AppColors.brand,
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.displayName, style: AppTextStyles.h2),
                  const SizedBox(height: 2),
                  Text(meta.hint, style: AppTextStyles.caption),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: AppDurations.fast,
              opacity: selected ? 1 : 0,
              child: const Icon(
                Icons.check_circle,
                color: AppColors.brand,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _RoleMeta _metaFor(SystemRole r) => switch (r) {
        SystemRole.customer => const _RoleMeta(
            Icons.person_outline_rounded,
            'Ставит задачи, принимает этапы, оплачивает',
          ),
        SystemRole.representative => const _RoleMeta(
            Icons.group_outlined,
            'Действует от имени заказчика по доверенности',
          ),
        SystemRole.contractor => const _RoleMeta(
            Icons.engineering_outlined,
            'Управляет этапами и мастерами',
          ),
        SystemRole.master => const _RoleMeta(
            Icons.construction_outlined,
            'Выполняет работы, отмечает шаги',
          ),
        SystemRole.admin => const _RoleMeta(
            Icons.shield_outlined,
            'Служебная роль — в приложении не выбирается',
          ),
      };
}

class _RoleMeta {
  const _RoleMeta(this.icon, this.hint);
  final IconData icon;
  final String hint;
}
