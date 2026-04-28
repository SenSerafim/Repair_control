import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';
import 'status_pill.dart';

/// Мини-карточка этапа в карусели консоли (s-console-* StagesScroll).
///
/// 160 ширина, 4 индикатора в столбик: подрядчик, прогресс шагов,
/// открытые вопросы, сроки. Каждый индикатор — иконка + текст или
/// «warning»-pill с цветным фоном при предупреждении.
class AppStageMiniCard extends StatelessWidget {
  const AppStageMiniCard({
    required this.title,
    required this.statusLabel,
    required this.statusKind,
    required this.assigneeName,
    required this.stepsLabel,
    required this.questionsLabel,
    required this.deadlineLabel,
    required this.progress,
    this.assigneeAlert = false,
    this.questionsAlert = false,
    this.deadlineAlert = _AlertKind.none,
    this.onTap,
    super.key,
  });

  final String title;

  /// «Завершён», «В работе», «Не начат», «Пауза», «На приёмке», «Отклонён».
  final String statusLabel;
  final AppStageMiniStatus statusKind;
  final String assigneeName;
  final String stepsLabel;
  final String questionsLabel;
  final String deadlineLabel;

  /// 0..1
  final double progress;

  /// `true` — подрядчик не назначен (красная пилюля).
  final bool assigneeAlert;

  /// `true` — есть открытые вопросы (жёлтая пилюля).
  final bool questionsAlert;

  /// Состояние сроков: ok / late (yellow pill) / overdue (red pill).
  final _AlertKind deadlineAlert;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (border, bg, primary) = _palette(statusKind);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        onTap: onTap,
        child: Container(
          width: 168,
          padding: const EdgeInsets.all(AppSpacing.x10),
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.n800,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _StatusBadge(label: statusLabel, kind: statusKind),
                ],
              ),
              const SizedBox(height: AppSpacing.x8),
              _Indicator(
                icon: PhosphorIconsRegular.userCircle,
                text: assigneeName,
                color: primary,
                alert: assigneeAlert ? _AlertKind.overdue : _AlertKind.none,
              ),
              const SizedBox(height: 5),
              _Indicator(
                icon: PhosphorIconsRegular.lightning,
                text: stepsLabel,
                color: primary,
              ),
              const SizedBox(height: 5),
              _Indicator(
                icon: PhosphorIconsRegular.question,
                text: questionsLabel,
                color: questionsAlert ? AppColors.yellowText : AppColors.n400,
                alert: questionsAlert ? _AlertKind.late : _AlertKind.none,
              ),
              const SizedBox(height: 5),
              _Indicator(
                icon: PhosphorIconsRegular.calendar,
                text: deadlineLabel,
                color: switch (deadlineAlert) {
                  _AlertKind.late => AppColors.yellowText,
                  _AlertKind.overdue => AppColors.redDot,
                  _AlertKind.none => primary,
                },
                alert: deadlineAlert,
              ),
              const SizedBox(height: AppSpacing.x8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: AppColors.n200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _progressColor(statusKind),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static (Color, Color, Color) _palette(AppStageMiniStatus s) {
    switch (s) {
      case AppStageMiniStatus.done:
        return (
          AppColors.greenDot,
          const Color(0xFFF0FDF4),
          AppColors.greenDark,
        );
      case AppStageMiniStatus.active:
        return (
          AppColors.brand,
          AppColors.brandLight,
          AppColors.blueText,
        );
      case AppStageMiniStatus.paused:
        return (
          AppColors.yellowDot,
          const Color(0xFFFFFBEB),
          AppColors.yellowText,
        );
      case AppStageMiniStatus.review:
        return (AppColors.brand, AppColors.brandLight, AppColors.blueText);
      case AppStageMiniStatus.rejected:
        return (AppColors.redDot, AppColors.redBg, AppColors.redText);
      case AppStageMiniStatus.pending:
        return (AppColors.n200, AppColors.n0, AppColors.n500);
    }
  }

  static Color _progressColor(AppStageMiniStatus s) => switch (s) {
        AppStageMiniStatus.done => AppColors.greenDot,
        AppStageMiniStatus.active => AppColors.brand,
        AppStageMiniStatus.paused => AppColors.yellowDot,
        AppStageMiniStatus.review => AppColors.brand,
        AppStageMiniStatus.rejected => AppColors.redDot,
        AppStageMiniStatus.pending => AppColors.n200,
      };
}

enum AppStageMiniStatus { done, active, paused, review, rejected, pending }

enum _AlertKind { none, late, overdue }

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.kind});

  final String label;
  final AppStageMiniStatus kind;

  @override
  Widget build(BuildContext context) {
    final s = switch (kind) {
      AppStageMiniStatus.done => Semaphore.green,
      AppStageMiniStatus.active => Semaphore.blue,
      AppStageMiniStatus.paused => Semaphore.yellow,
      AppStageMiniStatus.review => Semaphore.blue,
      AppStageMiniStatus.rejected => Semaphore.red,
      AppStageMiniStatus.pending => Semaphore.plan,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: s.text,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.icon,
    required this.text,
    required this.color,
    this.alert = _AlertKind.none,
  });

  final IconData icon;
  final String text;
  final Color color;
  final _AlertKind alert;

  @override
  Widget build(BuildContext context) {
    final isAlert = alert != _AlertKind.none;
    final (bg, fg) = switch (alert) {
      _AlertKind.late => (AppColors.yellowBg, AppColors.yellowText),
      _AlertKind.overdue => (AppColors.redBg, AppColors.redText),
      _AlertKind.none => (Colors.transparent, color),
    };

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: fg),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isAlert ? FontWeight.w700 : FontWeight.w600,
              color: fg,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (isAlert) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: row,
      );
    }
    return row;
  }
}
