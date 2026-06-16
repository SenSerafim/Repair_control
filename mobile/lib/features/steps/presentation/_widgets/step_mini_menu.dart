import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';

/// Мини-меню действий над шагом — c-step-menu.
///
/// 6 строк: добавить подшаг / фото / материал в заявку / задать вопрос /
/// отправить на согласование / доп.работа. Каждая — 42×42 цветная icon-tile +
/// 15px label. Закрывается сразу после выбора (Navigator.pop).
class StepMiniMenu extends StatelessWidget {
  const StepMiniMenu({
    required this.onAddSubstep,
    required this.onAddPhoto,
    required this.onAddMaterial,
    required this.onAskQuestion,
    required this.onSendForApproval,
    required this.onExtraWork,
    super.key,
  });

  /// Любой callback может быть `null` — соответствующий пункт меню
  /// тогда не рендерится. Решения по правам делает вызывающий
  /// (StepDetailScreen) через canInProjectProvider — здесь только рендер.
  final VoidCallback? onAddSubstep;
  final VoidCallback? onAddPhoto;

  /// NEWFIX TZ-фронт §11.5 — открыть форму создания заявки на материалы,
  /// прокинув контекст этапа этого шага.
  final VoidCallback? onAddMaterial;
  final VoidCallback? onAskQuestion;
  final VoidCallback? onSendForApproval;
  final VoidCallback? onExtraWork;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    void add({
      required IconData icon,
      required String label,
      required Color bg,
      required Color fg,
      required VoidCallback? cb,
    }) {
      if (cb == null) return;
      items.add(
        _MiniMenuItem(
          icon: icon,
          label: label,
          bg: bg,
          fg: fg,
          onTap: () {
            Navigator.of(context).pop();
            cb();
          },
        ),
      );
    }

    add(
      icon: Icons.format_list_bulleted_rounded,
      label: 'Добавить подшаг',
      bg: AppColors.brandLight,
      fg: AppColors.brand,
      cb: onAddSubstep,
    );
    add(
      icon: Icons.camera_alt_outlined,
      label: 'Добавить фото',
      bg: AppColors.brandLight,
      fg: AppColors.brand,
      cb: onAddPhoto,
    );
    add(
      icon: Icons.shopping_cart_outlined,
      label: 'Добавить материал в заявку',
      bg: AppColors.brandLight,
      fg: AppColors.brand,
      cb: onAddMaterial,
    );
    add(
      icon: Icons.help_outline_rounded,
      label: 'Задать вопрос',
      bg: AppColors.purpleBg,
      fg: AppColors.purple,
      cb: onAskQuestion,
    );
    add(
      icon: Icons.check_circle_outline_rounded,
      label: 'Отправить на согласование',
      bg: AppColors.yellowBg,
      fg: AppColors.yellowDot,
      cb: onSendForApproval,
    );
    add(
      icon: Icons.attach_money_rounded,
      label: 'Доп. работа с ценой',
      bg: AppColors.yellowBg,
      fg: AppColors.yellowDot,
      cb: onExtraWork,
    );
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Text(
          'Действий нет — нужны права на управление шагом.',
          style: TextStyle(fontSize: 14, color: Color(0xFF656b7a)),
          textAlign: TextAlign.center,
        ),
      );
    }
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
