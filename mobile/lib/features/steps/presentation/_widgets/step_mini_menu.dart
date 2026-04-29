import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';

/// Мини-меню действий над шагом — c-step-menu.
///
/// 5 строк: добавить подшаг / фото / задать вопрос / отправить на согласование /
/// доп.работа. Каждая — 42×42 цветная icon-tile + 15px label. Закрывается
/// сразу после выбора (Navigator.pop).
class StepMiniMenu extends StatelessWidget {
  const StepMiniMenu({
    required this.onAddSubstep,
    required this.onAddPhoto,
    required this.onAskQuestion,
    required this.onSendForApproval,
    required this.onExtraWork,
    super.key,
  });

  final VoidCallback onAddSubstep;
  final VoidCallback onAddPhoto;
  final VoidCallback onAskQuestion;
  final VoidCallback onSendForApproval;
  final VoidCallback onExtraWork;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MiniMenuItem(
        icon: Icons.format_list_bulleted_rounded,
        label: 'Добавить подшаг',
        bg: AppColors.brandLight,
        fg: AppColors.brand,
        onTap: () {
          Navigator.of(context).pop();
          onAddSubstep();
        },
      ),
      _MiniMenuItem(
        icon: Icons.camera_alt_outlined,
        label: 'Добавить фото',
        bg: AppColors.brandLight,
        fg: AppColors.brand,
        onTap: () {
          Navigator.of(context).pop();
          onAddPhoto();
        },
      ),
      _MiniMenuItem(
        icon: Icons.help_outline_rounded,
        label: 'Задать вопрос',
        bg: AppColors.purpleBg,
        fg: AppColors.purple,
        onTap: () {
          Navigator.of(context).pop();
          onAskQuestion();
        },
      ),
      _MiniMenuItem(
        icon: Icons.check_circle_outline_rounded,
        label: 'Отправить на согласование',
        bg: AppColors.yellowBg,
        fg: AppColors.yellowDot,
        onTap: () {
          Navigator.of(context).pop();
          onSendForApproval();
        },
      ),
      _MiniMenuItem(
        icon: Icons.attach_money_rounded,
        label: 'Доп. работа с ценой',
        bg: AppColors.yellowBg,
        fg: AppColors.yellowDot,
        onTap: () {
          Navigator.of(context).pop();
          onExtraWork();
        },
      ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, thickness: 1, color: AppColors.n100),
          items[i],
        ],
      ],
    );
  }
}

class _MiniMenuItem extends StatelessWidget {
  const _MiniMenuItem({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Icon(icon, size: 22, color: fg),
            ),
            const SizedBox(width: AppSpacing.x14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.subtitle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.n800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
