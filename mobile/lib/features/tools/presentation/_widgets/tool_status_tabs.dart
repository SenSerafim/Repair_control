import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';

enum ToolStatusTab { all, issued, warehouse }

/// Tabs (Все / Выданные / На складе) с counts для tool_issuances_screen.
class ToolStatusTabs extends StatelessWidget {
  const ToolStatusTabs({
    required this.selected,
    required this.onChanged,
    required this.allCount,
    required this.issuedCount,
    required this.warehouseCount,
    super.key,
  });

  final ToolStatusTab selected;
  final ValueChanged<ToolStatusTab> onChanged;
  final int allCount;
  final int issuedCount;
  final int warehouseCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.n0,
        border: Border(bottom: BorderSide(color: AppColors.n200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
      child: Row(
        children: [
          _Tab(
            label: 'Все',
            count: allCount,
            active: selected == ToolStatusTab.all,
            onTap: () => onChanged(ToolStatusTab.all),
          ),
          _Tab(
            label: 'Выданные',
            count: issuedCount,
            active: selected == ToolStatusTab.issued,
            onTap: () => onChanged(ToolStatusTab.issued),
          ),
          _Tab(
            label: 'На складе',
            count: warehouseCount,
            active: selected == ToolStatusTab.warehouse,
            onTap: () => onChanged(ToolStatusTab.warehouse),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.brand : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Center(
            child: Text(
              '$label ($count)',
              style: AppTextStyles.subtitle.copyWith(
                color: active ? AppColors.brand : AppColors.n400,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
