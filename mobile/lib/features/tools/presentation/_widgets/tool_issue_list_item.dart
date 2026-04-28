import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/tool.dart';

/// Item в списке выбора инструмента для выдачи (e-tool-issue):
/// 20×20 checkbox-square (selected) / 20×20 outline (available) / disabled
/// (issued — мутный + надпись «Выдан → <user>»).
class ToolIssueListItem extends StatelessWidget {
  const ToolIssueListItem({
    required this.tool,
    required this.selected,
    required this.disabled,
    required this.onTap,
    this.disabledReason,
    super.key,
  });

  final ToolItem tool;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  /// Текст под названием для disabled-инструментов («Выдан → Петров С.»).
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final dim = disabled;
    return InkWell(
      onTap: dim ? null : onTap,
      child: Opacity(
        opacity: dim ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x14,
            vertical: AppSpacing.x12,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.n100)),
          ),
          child: Row(
            children: [
              _Box(selected: selected, disabled: dim),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name,
                      style: AppTextStyles.subtitle.copyWith(
                        color: dim ? AppColors.n600 : AppColors.n800,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      dim
                          ? (disabledReason ?? 'Уже выдан')
                          : 'Свободно: ${tool.availableQty}',
                      style: AppTextStyles.tiny.copyWith(
                        color: AppColors.n400,
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (!dim)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(AppRadius.r8),
                  ),
                  child: Text(
                    'Свободен',
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.greenDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.selected, required this.disabled});

  final bool selected;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: disabled
            ? AppColors.n200
            : (selected ? AppColors.brand : Colors.transparent),
        border: disabled || selected
            ? null
            : Border.all(color: AppColors.n300, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      child: selected && !disabled
          ? const Icon(Icons.check_rounded, size: 12, color: AppColors.n0)
          : null,
    );
  }
}
