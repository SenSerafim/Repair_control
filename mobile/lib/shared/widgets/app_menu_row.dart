import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';

/// Строка меню (44×44 цветная иконка + label + value/sub + chevron).
///
/// Дизайн `Кластер A` (s-profile, s-help, s-notif-settings):
/// - profile-меню (Г1–Г4),
/// - help-контакты (Telegram/Phone),
/// - язык (флаг → label → value),
/// - notif-settings (label + sub + Switch).
class AppMenuRow extends StatelessWidget {
  const AppMenuRow({
    required this.label,
    this.icon,
    this.iconBg,
    this.iconColor,
    this.leading,
    this.value,
    this.valueColor,
    this.sub,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.disabled = false,
    super.key,
  });

  /// Основной заголовок ряда.
  final String label;

  /// Если задано — рендерится 44×44 круглая (квадрат+r12) плашка с иконкой.
  final IconData? icon;
  final Color? iconBg;
  final Color? iconColor;

  /// Альтернатива iconBg/icon — кастомный leading-виджет (флаг, фото и т.д.).
  final Widget? leading;

  /// Серое значение справа (например «Русский», «3 роли», «5 шт.»).
  final String? value;
  final Color? valueColor;

  /// Текст под label (12px grey) — для notif-settings и FAQ-rows.
  final String? sub;

  /// Кастомный trailing (Switch, Checkbox, кастомная стрелка). Перебивает chevron.
  final Widget? trailing;

  final VoidCallback? onTap;

  /// `true` — красный текст label, без иконки и chevron (Удалить аккаунт).
  final bool danger;

  /// `true` — затемнённый ряд, без onTap (Always-on critical).
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final labelColor = danger
        ? AppColors.redText
        : disabled
            ? AppColors.n400
            : AppColors.n700;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x12,
      ),
      child: Row(
        children: [
          if (leading != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.x12),
              child: leading,
            )
          else if (icon != null) ...[
            _IconBadge(
              icon: icon!,
              bg: iconBg ?? AppColors.n100,
              color: iconColor ?? AppColors.n600,
            ),
            const SizedBox(width: AppSpacing.x12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                    letterSpacing: -0.1,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.n400,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else ...[
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.x6),
                child: Text(
                  value!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.n400,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            if (onTap != null && !danger)
              const Icon(
                PhosphorIconsRegular.caretRight,
                size: 16,
                color: AppColors.n300,
              ),
          ],
        ],
      ),
    );

    if (onTap == null || disabled) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: row,
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.bg,
    required this.color,
  });

  final IconData icon;
  final Color bg;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

/// Группа меню с белым фоном, скруглёнными углами и тенью sh1 — для Profile.
class AppMenuGroup extends StatelessWidget {
  const AppMenuGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(
          Container(
            margin: const EdgeInsets.only(left: 14 + 40 + 12),
            height: 1,
            color: AppColors.n100,
          ),
        );
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.sh1,
      ),
      child: Column(children: items),
    );
  }
}
