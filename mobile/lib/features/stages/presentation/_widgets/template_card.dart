import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/template.dart';

/// Карточка шаблона этапа — c-templates.
///
/// 40×40 цветная icon-tile (цвет/иконка маппится по канонической русской
/// title-строке платформенного шаблона), title, «{N} шагов», chevron.
class TemplateCard extends StatelessWidget {
  const TemplateCard({
    required this.template,
    required this.onTap,
    super.key,
  });

  final StageTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spec = _iconFor(template.title);
    return Material(
      color: AppColors.n0,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            color: AppColors.n0,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.n200),
            boxShadow: AppShadows.sh1,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: spec.bg,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: Icon(spec.icon, size: 22, color: spec.fg),
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.n900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${template.steps.length} ${_pluralSteps(template.steps.length)}',
                      style: AppTextStyles.tiny.copyWith(
                        color: AppColors.n400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.n300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _pluralSteps(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'шаг';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return 'шага';
    }
    return 'шагов';
  }
}

/// Маппинг канонических заголовков платформенных шаблонов в иконку и палитру.
({IconData icon, Color bg, Color fg}) _iconFor(String title) {
  final t = title.toLowerCase();
  if (t.contains('демонтаж')) {
    return (
      icon: Icons.delete_outline_rounded,
      bg: AppColors.redBg,
      fg: AppColors.redText,
    );
  }
  if (t.contains('электрик')) {
    return (
      icon: Icons.bolt_rounded,
      bg: AppColors.yellowBg,
      fg: AppColors.yellowText,
    );
  }
  if (t.contains('сантехник')) {
    return (
      icon: Icons.water_drop_outlined,
      bg: AppColors.blueBg,
      fg: AppColors.blueText,
    );
  }
  if (t.contains('штукатурк') || t.contains('стяжк')) {
    return (
      icon: Icons.layers_rounded,
      bg: AppColors.greenLight,
      fg: AppColors.greenDark,
    );
  }
  if (t.contains('плитк')) {
    return (
      icon: Icons.grid_on_rounded,
      bg: AppColors.purpleBg,
      fg: AppColors.purple,
    );
  }
  if (t.contains('покраск') || t.contains('обои')) {
    return (
      icon: Icons.format_paint_outlined,
      bg: AppColors.brandLight,
      fg: AppColors.brand,
    );
  }
  if (t.contains('пол')) {
    return (
      icon: Icons.crop_square_rounded,
      bg: AppColors.n100,
      fg: AppColors.n600,
    );
  }
  if (t.contains('кондицион')) {
    return (
      icon: Icons.air_rounded,
      bg: const Color(0xFFCFFAFE),
      fg: const Color(0xFF0E7490),
    );
  }
  return (
    icon: Icons.dashboard_rounded,
    bg: AppColors.brandLight,
    fg: AppColors.brand,
  );
}
