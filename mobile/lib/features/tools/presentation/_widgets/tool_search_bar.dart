import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';

/// Search-input для tool_issuances_screen — search by name / serial / location.
class ToolSearchBar extends StatelessWidget {
  const ToolSearchBar({
    required this.controller,
    required this.onChanged,
    this.hint = 'Название, серийный №, склад…',
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.n0,
        border: Border.all(color: AppColors.n200, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 16,
            color: AppColors.n400,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppTextStyles.caption.copyWith(
                  color: AppColors.n400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
