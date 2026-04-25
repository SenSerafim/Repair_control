import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Темно-синий 3-stop gradient header. Соответствует `.screen-header` /
/// `.prof-hero` из дизайна (Кластер B Console + Кластер A Profile).
///
/// Console: 160deg, #0D1840 → #1E2F6B (60%) → #2A3A7A
/// Profile: 155deg, #0F172A → #1A2D5A (60%) → #2A3F7E
///
/// Соответствует angle-Alignment paradigm Flutter (160° HTML ≈
/// `Alignment.topLeft` → `Alignment.bottomRight` с лёгким сдвигом).
enum HeroPalette {
  console,
  profile;

  List<Color> get colors => switch (this) {
        HeroPalette.console => const [
            Color(0xFF0D1840),
            Color(0xFF1E2F6B),
            Color(0xFF2A3A7A),
          ],
        HeroPalette.profile => const [
            Color(0xFF0F172A),
            Color(0xFF1A2D5A),
            Color(0xFF2A3F7E),
          ],
      };

  List<double> get stops => const [0.0, 0.6, 1.0];
}

class AppGradientHero extends StatelessWidget {
  const AppGradientHero({
    required this.child,
    this.palette = HeroPalette.console,
    this.padding = const EdgeInsets.fromLTRB(20, 64, 20, 28),
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final HeroPalette palette;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // 160° ≈ направление от верх-лево к низ-право, чуть-чуть по
          // часовой стрелке. Aproximate соответствие CSS angle.
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.colors,
          stops: palette.stops,
        ),
        borderRadius: borderRadius,
        boxShadow: AppShadows.shBlue,
      ),
      child: child,
    );
  }
}
