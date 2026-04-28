import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import 'status_pill.dart';

/// Дом-прогресс из Cluster B (`s-console-*`).
///
/// 160×130 SVG-композиция: внешний track-arc + сегмент-arc прогресса,
/// стилизованная иконка дома в центре (roof + body + window), small
/// status-dot (зелёный/жёлтый/красный/синий) на нижнем срезе дома,
/// крупная цифра процента под домом, опциональный подзаголовок.
///
/// Цвет — по semaphore. При 100% пульсация по spread-shadow.
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
    final w = widget.size;
    final h = w * 130 / 160;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return SizedBox(
              width: w,
              height: h,
              child: CustomPaint(
                painter: _HousePainter(
                  percent: p,
                  arcColor: widget.semaphore.dot,
                  trackColor: widget.semaphore.bg,
                  percentColor: widget.semaphore.text,
                  pulse: p >= 100 ? _ctrl.value : 0,
                ),
              ),
            );
          },
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: AppSpacing.x6),
          Text(
            widget.subtitle!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: widget.semaphore.text,
            ),
          ),
        ],
      ],
    );
  }
}

class _HousePainter extends CustomPainter {
  _HousePainter({
    required this.percent,
    required this.arcColor,
    required this.trackColor,
    required this.percentColor,
    required this.pulse,
  });

  final int percent;
  final Color arcColor;
  final Color trackColor;
  final Color percentColor;
  final double pulse; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    // Координатная система оригинала — 160×130. Все вычисления масштабируются
    // под фактический size.
    final scaleX = size.width / 160;
    final scaleY = size.height / 130;
    Offset px(double x, double y) => Offset(x * scaleX, y * scaleY);

    final center = px(80, 65);
    final radius = 54.0 * scaleX;

    // 1. Track (полный круг). Дизайн: opacity 0.3 от ярко-цветного фона.
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * scaleX
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      trackPaint,
    );

    // 2. Progress arc.
    if (percent > 0) {
      final arcPaint = Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * scaleX
        ..strokeCap = StrokeCap.round;
      final sweep = 2 * math.pi * (percent / 100);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        arcPaint,
      );
    }

    // 3. Глоу при 100%.
    if (percent >= 100) {
      final glow = Paint()
        ..color = arcColor.withValues(alpha: 0.18 + 0.18 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, radius * (0.95 + 0.05 * pulse), glow);
    }

    // 4. Дом — заливка roof + body, светлый track-color, обводка arcColor.
    // SVG-эталон:
    //   path: M80 38 l-20 16 v22 a2 2 0 0 0 2 2 h36 a2 2 0 0 0 2-2 V54 z (roof+body)
    //   rect: x=73 y=64 w=14 h=14 (window/door)
    //   path roof: M60 54 l20-16 l20 16 (top contour)
    final housePath = Path()
      ..moveTo(px(80, 38).dx, px(80, 38).dy)
      ..lineTo(px(60, 54).dx, px(60, 54).dy)
      ..lineTo(px(60, 76).dx, px(60, 76).dy)
      ..lineTo(px(98, 76).dx, px(98, 76).dy)
      ..lineTo(px(100, 76).dx, px(100, 76).dy)
      ..lineTo(px(100, 54).dx, px(100, 54).dy)
      ..close();

    final houseFill = Paint()..color = trackColor;
    canvas.drawPath(housePath, houseFill);

    final houseStroke = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scaleX
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(housePath, houseStroke);

    // 5. Окно/дверь.
    final windowRect = Rect.fromLTWH(
      px(73, 64).dx,
      px(73, 64).dy,
      14 * scaleX,
      14 * scaleY,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(windowRect, Radius.circular(1 * scaleX)),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(windowRect, Radius.circular(1 * scaleX)),
      Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 * scaleX,
    );

    // 6. Status dot — маленький круг в нижней части дома (центр 80,68).
    final dotCenter = px(80, 68);
    canvas.drawCircle(dotCenter, 11 * scaleX, Paint()..color = arcColor);

    // 6.1. Иконка внутри dot — check / info / x в зависимости от прогресса.
    final tickPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scaleX
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (percent >= 100) {
      // Check: M75 68 l3.5 3.5 L85 64
      canvas.drawPath(
        Path()
          ..moveTo(px(75, 68).dx, px(75, 68).dy)
          ..lineTo(px(78.5, 71.5).dx, px(78.5, 71.5).dy)
          ..lineTo(px(85, 64).dx, px(85, 64).dy),
        tickPaint,
      );
    } else {
      // Default check sign for any non-100
      canvas.drawPath(
        Path()
          ..moveTo(px(75, 68).dx, px(75, 68).dy)
          ..lineTo(px(78.5, 71.5).dx, px(78.5, 71.5).dy)
          ..lineTo(px(85, 64).dx, px(85, 64).dy),
        tickPaint,
      );
    }

    // 7. Процент — крупная цифра под центром, y=105 в нативе.
    final tp = TextPainter(
      text: TextSpan(
        text: '$percent%',
        style: TextStyle(
          color: percentColor,
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w900,
          fontSize: 22 * scaleX,
          letterSpacing: -1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        size.width / 2 - tp.width / 2,
        105 * scaleY - tp.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _HousePainter old) =>
      old.percent != percent ||
      old.arcColor != arcColor ||
      old.trackColor != trackColor ||
      old.percentColor != percentColor ||
      old.pulse != pulse;
}
