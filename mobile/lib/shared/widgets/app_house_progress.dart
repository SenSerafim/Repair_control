import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';
import 'status_pill.dart';

/// Дом-прогресс-виджет (геймификация). Соответствует .house-section
/// из консоли кластера B.
///
/// Круговой arc (прогресс 0–100%), стилизованный house-icon в центре,
/// процент снизу. Цвет — по semaphore. При 100% — мягкий «pulse».
class AppHouseProgress extends StatefulWidget {
  const AppHouseProgress({
    required this.percent,
    required this.semaphore,
    this.subtitle,
    this.size = 160,
    super.key,
  });

  /// 0–100.
  final int percent;
  final Semaphore semaphore;
  final String? subtitle;
  final double size;

  @override
  State<AppHouseProgress> createState() => _AppHouseProgressState();
}

class _AppHouseProgressState extends State<AppHouseProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _maybeStartPulse();
  }

  @override
  void didUpdateWidget(covariant AppHouseProgress old) {
    super.didUpdateWidget(old);
    _maybeStartPulse();
  }

  void _maybeStartPulse() {
    if (widget.percent >= 100) {
      if (!_ctrl.isAnimating) _ctrl.repeat(reverse: true);
    } else {
      if (_ctrl.isAnimating) _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.percent.clamp(0, 100);
    return Column(
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size * 0.85,
          child: CustomPaint(
            painter: _HousePainter(
              percent: p,
              color: widget.semaphore.dot,
              trackColor: widget.semaphore.bg,
              textColor: widget.semaphore.text,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, child) {
                      final scale = 1.0 + (_ctrl.value * 0.15);
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.semaphore.dot,
                        shape: BoxShape.circle,
                        boxShadow: p >= 100
                            ? [
                                BoxShadow(
                                  color: widget.semaphore.dot.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: _progressIcon(p),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: AppSpacing.x6),
          Text(
            widget.subtitle!,
            style: AppTextStyles.caption.copyWith(
              color: widget.semaphore.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _progressIcon(int p) {
    if (p >= 100) {
      return const Icon(
        Icons.check_rounded,
        color: AppColors.n0,
        size: 22,
      );
    }
    if (widget.semaphore == Semaphore.red) {
      return const Icon(
        Icons.priority_high_rounded,
        color: AppColors.n0,
        size: 22,
      );
    }
    return const Icon(
      Icons.home_rounded,
      color: AppColors.n0,
      size: 22,
    );
  }
}

class _HousePainter extends CustomPainter {
  _HousePainter({
    required this.percent,
    required this.color,
    required this.trackColor,
    required this.textColor,
  });

  final int percent;
  final Color color;
  final Color trackColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final radius = size.width * 0.34;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      trackPaint,
    );

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final sweep = 2 * math.pi * (percent / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progressPaint,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '$percent%',
        style: TextStyle(
          color: textColor,
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w900,
          fontSize: 22,
          letterSpacing: -1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        center.dx - tp.width / 2,
        center.dy + radius + 6,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _HousePainter old) =>
      old.percent != percent ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.textColor != textColor;
}
