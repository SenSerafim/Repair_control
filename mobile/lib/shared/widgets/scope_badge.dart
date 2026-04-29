import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Pill-badge для типа согласования — `Шаг` / `Доп. работа` / `Приёмка этапа`
/// и т. д. Цвет фона/текста задаётся через `tone`.
///
/// Дизайн `design/Кластер D` карточки списка: 10px font / w800 / 3:8 padding /
/// pill-radius. Иконка 12×12 опционально слева.
enum ScopeBadgeTone {
  step, // purple
  extraWork, // yellow
  stageAccept, // brand
  plan, // brand
  deadline, // yellow
  question, // purple
  category, // нейтральный n100/n600 — для chip «Электрика», «Демонтаж»
  success, // green — для history-таба «Одобрено»
  danger, // red — «Отклонено»
}

class ScopeBadge extends StatelessWidget {
  const ScopeBadge({
    required this.label,
    required this.tone,
    this.icon,
    super.key,
  });

  final String label;
  final ScopeBadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _palette(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
              height: 1.2,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, Color) _palette(ScopeBadgeTone tone) {
    switch (tone) {
      case ScopeBadgeTone.step:
      case ScopeBadgeTone.question:
        return (AppColors.purpleBg, AppColors.purple);
      case ScopeBadgeTone.extraWork:
      case ScopeBadgeTone.deadline:
        return (AppColors.yellowBg, AppColors.yellowText);
      case ScopeBadgeTone.stageAccept:
      case ScopeBadgeTone.plan:
        return (AppColors.brandLight, AppColors.brand);
      case ScopeBadgeTone.category:
        return (AppColors.n100, AppColors.n600);
      case ScopeBadgeTone.success:
        return (AppColors.greenLight, AppColors.greenDark);
      case ScopeBadgeTone.danger:
        return (AppColors.redBg, AppColors.redText);
    }
  }
}
