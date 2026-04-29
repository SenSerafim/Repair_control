import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

enum StageTab { checklist, approvals, docs, chat }

extension StageTabX on StageTab {
  String get label => switch (this) {
        StageTab.checklist => 'Чек-лист',
        StageTab.approvals => 'Согл.',
        StageTab.docs => 'Докум.',
        StageTab.chat => 'Чат',
      };
}

/// 4-таб панель в детали этапа.
///
/// Дизайн c-stage-active: 2.5px brand-underline на active, brand text на active,
/// n400 на остальных. На вкладке «Согл.» — 16×16 красный badge с числом, если
/// pending > 0.
class StageTabsBar extends StatelessWidget {
  const StageTabsBar({
    required this.active,
    required this.onChange,
    this.approvalsBadge = 0,
    super.key,
  });

  final StageTab active;
  final ValueChanged<StageTab> onChange;
  final int approvalsBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.n0,
        border: Border(bottom: BorderSide(color: AppColors.n200)),
      ),
      child: Row(
        children: [
          for (final tab in StageTab.values)
            Expanded(
              child: _TabItem(
                label: tab.label,
                active: tab == active,
                badge: tab == StageTab.approvals && approvalsBadge > 0
                    ? approvalsBadge
                    : null,
                onTap: () => onChange(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool active;
  final int? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brand : AppColors.n400;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: active
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.brand, width: 2.5),
                  ),
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.1,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: AppSpacing.x6),
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.redDot,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.n0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
