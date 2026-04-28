import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';

/// Семантика роли для AppRoleCard / role-grid.
///
/// 4 явные роли — соответствуют backend `SystemRole` (без admin):
/// - customer = Заказчик
/// - representative = Представитель
/// - foreman = Бригадир (backend `contractor`)
/// - master = Мастер (на бекенде также называется «Подрядчик/Мастер» —
///   мастер регистрируется и приглашается как `master`)
enum AppRoleKind {
  customer,
  representative,
  foreman,
  master;

  String get displayName => switch (this) {
        AppRoleKind.customer => 'Заказчик',
        AppRoleKind.representative => 'Представитель',
        AppRoleKind.foreman => 'Бригадир',
        AppRoleKind.master => 'Мастер',
      };

  String get description => switch (this) {
        AppRoleKind.customer => 'Создаёт проекты, управляет бюджетом',
        AppRoleKind.representative =>
          'Доверенное лицо заказчика или бригадира',
        AppRoleKind.foreman =>
          'Ведёт работы по этапам, нанимает мастеров',
        AppRoleKind.master => 'Подрядчик · выполняет шаги на этапах',
      };

  IconData get icon => switch (this) {
        AppRoleKind.customer => PhosphorIconsFill.user,
        AppRoleKind.representative => PhosphorIconsFill.usersThree,
        AppRoleKind.foreman => PhosphorIconsFill.wrench,
        AppRoleKind.master => PhosphorIconsFill.hardHat,
      };

  LinearGradient get gradient => switch (this) {
        AppRoleKind.customer => AppGradients.avatarBlue,
        AppRoleKind.representative => AppGradients.avatarPurple,
        AppRoleKind.foreman => AppGradients.avatarGreen,
        AppRoleKind.master => AppGradients.avatarYellow,
      };
}

/// Карточка-выбор роли.
///
/// Используется в:
/// - registr-форме: 3 в сетке (compact = true);
/// - bottom-sheet «Добавить роль»: 1 в строке, с описанием справа;
/// - Member-Found «На проект» / «На этап» (тогда передаётся свой icon/name).
class AppRoleCard extends StatelessWidget {
  const AppRoleCard({
    required this.title,
    required this.icon,
    this.subtitle,
    this.gradient,
    this.selected = false,
    this.compact = false,
    this.onTap,
    super.key,
  });

  /// Конструктор по [AppRoleKind] — заполняет title/subtitle/icon/gradient.
  AppRoleCard.kind({
    required AppRoleKind kind,
    bool selected = false,
    bool compact = false,
    VoidCallback? onTap,
    Key? key,
  }) : this(
          key: key,
          title: kind.displayName,
          subtitle: kind.description,
          icon: kind.icon,
          gradient: kind.gradient,
          selected: selected,
          compact: compact,
          onTap: onTap,
        );

  final String title;
  final String? subtitle;
  final IconData icon;
  final LinearGradient? gradient;
  final bool selected;

  /// `true` — для сетки регистрации (3 в строке, без subtitle).
  /// `false` — для bottom-sheet (Row: иконка слева, текст по центру, без chevron).
  final bool compact;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.brand : AppColors.n200;
    final bgColor = selected ? AppColors.brandLight : AppColors.n0;

    return Material(
      color: bgColor,
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.x8 : AppSpacing.x14,
            vertical: AppSpacing.x14,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2),
            borderRadius: AppRadius.card,
          ),
          child: compact ? _buildCompact() : _buildRow(),
        ),
      ),
    );
  }

  Widget _buildCompact() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _icon(44),
        const SizedBox(height: AppSpacing.x10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.n700,
            letterSpacing: -0.1,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.x4),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.n400,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildRow() {
    return Row(
      children: [
        _icon(44),
        const SizedBox(width: AppSpacing.x12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.n700,
                  letterSpacing: -0.1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.n400,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onTap != null && !selected)
          Icon(PhosphorIconsRegular.caretRight, size: 18, color: AppColors.n300),
        if (selected)
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.brand,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsBold.check,
              size: 14,
              color: AppColors.n0,
            ),
          ),
      ],
    );
  }

  Widget _icon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.avatarGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.n0, size: size * 0.45),
    );
  }
}
