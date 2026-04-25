import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Контейнер с пунктирной рамкой — используется в upload-зонах
/// (документы / фото) согласно дизайну `Кластер E/F`.
///
/// Параметры по умолчанию совпадают с `_DashedBorderPainter` из
/// `document_upload_screen.dart`: dash 8, gap 6, stroke 2px, radius r20.
class AppDashedBorder extends StatelessWidget {
  const AppDashedBorder({
    required this.child,
    this.color = AppColors.n300,
    this.strokeWidth = 2,
    this.dashLength = 8,
    this.gapLength = 6,
    this.borderRadius = AppRadius.r20,
    this.padding = const EdgeInsets.all(AppSpacing.x16),
    this.height = 160,
    super.key,
  });

  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  /// Если задан — фиксирует высоту (для drop-zone). null — растягивается
  /// под контент.
  final double? height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
        radius: borderRadius,
      ),
      child: Container(
        height: height,
        alignment: height != null ? Alignment.center : null,
        padding: padding,
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      var d = 0.0;
      while (d < m.length) {
        final end = (d + dashLength).clamp(0.0, m.length);
        canvas.drawPath(m.extractPath(d, end), paint);
        d = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength ||
      old.radius != radius;
}
