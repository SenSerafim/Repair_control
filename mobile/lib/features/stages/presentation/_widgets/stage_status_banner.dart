import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import 'stage_banner_data.dart';

/// Banner с состоянием этапа (8 вариантов c-stage-*).
///
/// Один виджет, switch по типу [data]. Active вариант тикает таймером раз в
/// секунду; остальные варианты статичные.
class StageStatusBanner extends StatelessWidget {
  const StageStatusBanner({required this.data, this.onContact, super.key});

  final StageBannerData data;

  /// Используется только для overdue — открывает чат с заказчиком.
  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    return switch (data) {
      ActiveTimerBanner(:final startedAt) => _ActiveTimer(startedAt: startedAt),
      PausedDeadlineShiftBanner(:final originalEnd, :final newEnd) =>
        _PausedShift(originalEnd: originalEnd, newEnd: newEnd),
      ReviewBanner() => const _Review(),
      OverdueBanner(:final daysLate) =>
        _Overdue(daysLate: daysLate, onContact: onContact),
      LateStartBanner(:final startedDue) => _LateStart(startedDue: startedDue),
      RejectedBanner(
        :final reasonText,
        :final actorName,
        :final attempt,
      ) =>
        _Rejected(reasonText: reasonText, actorName: actorName, attempt: attempt),
      WaitingNoContractorBanner() => const _WaitingNoContractor(),
      DoneBanner() => const _Done(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────
// Active — brand-bg бар с тикающим таймером
// ─────────────────────────────────────────────────────────────────────
class _ActiveTimer extends StatefulWidget {
  const _ActiveTimer({required this.startedAt});

  final DateTime startedAt;

  @override
  State<_ActiveTimer> createState() => _ActiveTimerState();
}

class _ActiveTimerState extends State<_ActiveTimer> {
  late Timer _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.startedAt);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(widget.startedAt));
      }
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _elapsed.inHours.remainder(24).toString().padLeft(2, '0');
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final daysLabel = '${_elapsed.inDays} ${_pluralDays(_elapsed.inDays)}';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x12,
      ),
      decoration: BoxDecoration(
        gradient: AppGradients.brandButton,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.shBlue,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.n0,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.x10),
          Text(
            '$h:$m:$s',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.n0,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Text(
              'Таймер запущен · $daysLabel',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.n0.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _pluralDays(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'день';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return 'дня';
    return 'дней';
  }
}

// ─────────────────────────────────────────────────────────────────────
// Paused — yellow с дедлайн-сдвигом
// ─────────────────────────────────────────────────────────────────────
class _PausedShift extends StatelessWidget {
  const _PausedShift({this.originalEnd, this.newEnd});

  final DateTime? originalEnd;
  final DateTime? newEnd;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM', 'ru');
    final shifted = originalEnd != null && newEnd != null
        ? '${df.format(originalEnd!)} → ${df.format(newEnd!)}'
        : null;
    return _BaseBanner(
      bg: AppColors.yellowBg,
      border: AppColors.yellowDot.withValues(alpha: 0.4),
      icon: Icons.pause_circle_outline_rounded,
      iconColor: AppColors.yellowText,
      title: 'Этап на паузе',
      subtitle: shifted == null
          ? 'Возобновите, когда будет готово.'
          : 'Дедлайн сдвинут: $shifted.',
      titleColor: AppColors.yellowText,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Review — purple gradient
// ─────────────────────────────────────────────────────────────────────
class _Review extends StatelessWidget {
  const _Review();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x14,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        ),
        borderRadius: AppRadius.card,
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D6D28D9),
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fact_check_outlined, color: AppColors.n0, size: 22),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Проверьте работу',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.n0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Все шаги выполнены, этап ждёт вашего решения.',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.n0.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Overdue — red с днями просрочки и «Связаться»
// ─────────────────────────────────────────────────────────────────────
class _Overdue extends StatelessWidget {
  const _Overdue({required this.daysLate, this.onContact});

  final int daysLate;
  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    return _BaseBanner(
      bg: AppColors.redBg,
      border: AppColors.redDot.withValues(alpha: 0.4),
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.redText,
      title: 'Просрочен',
      subtitle: 'Дедлайн истёк ${_pluralDaysAgo(daysLate)}.',
      titleColor: AppColors.redText,
      action: onContact == null
          ? null
          : TextButton(
              onPressed: onContact,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Связаться →',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand,
                ),
              ),
            ),
    );
  }

  String _pluralDaysAgo(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return '$n день назад';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return '$n дня назад';
    }
    return '$n дней назад';
  }
}

// ─────────────────────────────────────────────────────────────────────
// LateStart — yellow «Дата старта прошла»
// ─────────────────────────────────────────────────────────────────────
class _LateStart extends StatelessWidget {
  const _LateStart({this.startedDue});

  final DateTime? startedDue;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM', 'ru');
    final dateLabel = startedDue == null ? '' : ' (${df.format(startedDue!)})';
    return _BaseBanner(
      bg: AppColors.yellowBg,
      border: AppColors.yellowDot.withValues(alpha: 0.4),
      icon: Icons.hourglass_top_rounded,
      iconColor: AppColors.yellowText,
      title: 'Не начат вовремя',
      subtitle:
          'Дата старта$dateLabel прошла. Назначьте подрядчика и нажмите «Старт».',
      titleColor: AppColors.yellowText,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Rejected — red box с reason
// ─────────────────────────────────────────────────────────────────────
class _Rejected extends StatelessWidget {
  const _Rejected({
    required this.reasonText,
    required this.actorName,
    required this.attempt,
  });

  final String reasonText;
  final String actorName;
  final int attempt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.redBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.redDot.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.close_rounded, size: 20, color: AppColors.redText),
              const SizedBox(width: AppSpacing.x8),
              Text(
                'Причина отклонения',
                style: AppTextStyles.subtitle.copyWith(color: AppColors.redText),
              ),
            ],
          ),
          if (reasonText.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x8),
            Text(
              reasonText,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.redText,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.x6),
          Text(
            actorName.isEmpty
                ? 'Попытка $attempt'
                : '$actorName · Попытка $attempt',
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.redText.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Waiting — красный «Подрядчик не назначен»
// ─────────────────────────────────────────────────────────────────────
class _WaitingNoContractor extends StatelessWidget {
  const _WaitingNoContractor();

  @override
  Widget build(BuildContext context) {
    return _BaseBanner(
      bg: AppColors.redBg,
      border: AppColors.redDot.withValues(alpha: 0.4),
      icon: Icons.person_off_outlined,
      iconColor: AppColors.redText,
      title: 'Подрядчик не назначен',
      subtitle: 'Этап не может быть запущен.',
      titleColor: AppColors.redText,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Done — лёгкий зелёный «В срок»
// ─────────────────────────────────────────────────────────────────────
class _Done extends StatelessWidget {
  const _Done();

  @override
  Widget build(BuildContext context) {
    return _BaseBanner(
      bg: AppColors.greenLight,
      border: AppColors.greenDot.withValues(alpha: 0.4),
      icon: Icons.verified_outlined,
      iconColor: AppColors.greenDark,
      title: 'Завершён',
      subtitle: 'Этап принят. Спасибо за работу!',
      titleColor: AppColors.greenDark,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Базовый banner — иконка + title + subtitle + опц. action.
// ─────────────────────────────────────────────────────────────────────
class _BaseBanner extends StatelessWidget {
  const _BaseBanner({
    required this.bg,
    required this.border,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    this.action,
  });

  final Color bg;
  final Color border;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.card,
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(color: titleColor),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: titleColor.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: AppSpacing.x6),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
