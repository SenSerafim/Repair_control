import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/template.dart';

/// Тело экрана-превью шаблона — c-template-preview.
///
/// Header (48×48 цветная иконка + title + sub «N шагов · предустановленный»),
/// numbered checklist шагов, blue info-box, sticky bottom CTA.
class TemplatePreviewBody extends StatelessWidget {
  const TemplatePreviewBody({
    required this.template,
    required this.onApply,
    this.isApplying = false,
    super.key,
  });

  final StageTemplate template;
  final VoidCallback onApply;
  final bool isApplying;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x16,
              AppSpacing.x16,
              AppSpacing.x16,
              AppSpacing.x12,
            ),
            children: [
              _Header(template: template),
              const SizedBox(height: AppSpacing.x20),
              if (template.steps.isNotEmpty) ...[
                Text(
                  'ЧЕК-ЛИСТ ШАГОВ',
                  style: AppTextStyles.tiny.copyWith(
                    color: AppColors.n400,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.x8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.n0,
                    borderRadius: AppRadius.card,
                    border: Border.all(color: AppColors.n200),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < template.steps.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.n100,
                          ),
                        _StepRow(
                          number: i + 1,
                          title: template.steps[i].title,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.x16),
              Container(
                padding: const EdgeInsets.all(AppSpacing.x14),
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: AppRadius.card,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.brand,
                    ),
                    const SizedBox(width: AppSpacing.x8),
                    Expanded(
                      child: Text(
                        'Шаблон будет скопирован. Вы сможете отредактировать '
                        'название, шаги и сроки после создания.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.brandDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x16,
            AppSpacing.x12,
            AppSpacing.x16,
            AppSpacing.x32 + 4,
          ),
          decoration: const BoxDecoration(
            color: AppColors.n0,
            border: Border(top: BorderSide(color: AppColors.n200)),
          ),
          child: AppButton(
            label: 'Создать этап из шаблона',
            icon: Icons.add_rounded,
            isLoading: isApplying,
            onPressed: isApplying ? null : onApply,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.template});

  final StageTemplate template;

  @override
  Widget build(BuildContext context) {
    final spec = _iconForTitle(template.title);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: spec.bg,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Icon(spec.icon, size: 24, color: spec.fg),
        ),
        const SizedBox(width: AppSpacing.x12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.title,
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 2),
              Text(
                '${template.steps.length} ${_pluralSteps(template.steps.length)} · ${template.kind == TemplateKind.platform ? 'предустановленный шаблон' : 'мой шаблон'}',
                style: AppTextStyles.tiny.copyWith(color: AppColors.n400),
              ),
            ],
          ),
        ),
      ],
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

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.title});

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x14,
        AppSpacing.x12,
        AppSpacing.x14,
        AppSpacing.x12,
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.n300, width: 1.5),
            ),
            child: Text(
              '$number',
              style: AppTextStyles.tiny.copyWith(color: AppColors.n400),
            ),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: AppColors.n800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Locally re-export icon mapping (unable to import private from template_card.dart).
({IconData icon, Color bg, Color fg}) _iconForTitle(String title) {
  // duplicates the mapping in template_card.dart
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
