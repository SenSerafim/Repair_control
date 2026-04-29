import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import 'celebration/_house_segments.dart';
import 'status_pill.dart';

/// Дом-прогресс из `design/house_animation.html`.
///
/// 9-слойная архитектурная композиция, появляющаяся по мере роста
/// прогресса (фундамент → цоколь → стены 1F → перекрытие → стены 2F →
/// стропила → кровля → фасад → окна+труба+дым). На 100% включается
/// мягкий пульсирующий glow и появляются sparkles. WOW-overlay
/// (confetti + banner) показывается отдельно через
/// `HouseCelebrationOverlay.show(...)` из `console_screen.dart`.
///
/// Параметр [bouncePulse] — счётчик-сигнал «закрылся очередной этап».
/// Любое его изменение запускает 700ms bounce-анимацию (scale 1→1.07→
/// 0.97→1.02→1) с easeOutBack-кривой.
class AppHouseProgress extends StatefulWidget {
  const AppHouseProgress({
    required this.percent,
    required this.semaphore,
    this.subtitle,
    this.size = 220,
    this.bouncePulse = 0,
    super.key,
  });

  /// 0–100.
  final int percent;
  final Semaphore semaphore;
  final String? subtitle;

  /// Ширина дома в логических пикселях. Высота сцены = `size * 240/220`.
  /// По умолчанию 220 (1:1 с HTML-эталоном). Можно уменьшить до 160 для
  /// компактных мест.
  final double size;

  /// Increment счётчик при закрытии очередного этапа — запустит bounce.
  final int bouncePulse;

  @override
  State<AppHouseProgress> createState() => _AppHouseProgressState();
}

class _AppHouseProgressState extends State<AppHouseProgress>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  late final AnimationController _bounceCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  late final Animation<double> _bounceScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.07), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 1.07, end: 0.97), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.02), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 1.02, end: 1), weight: 25),
  ]).animate(
    CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut),
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
    if (old.bouncePulse != widget.bouncePulse) {
      _bounceCtrl.forward(from: 0);
    }
  }

  void _maybeStartPulse() {
    if (widget.percent >= 100) {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else {
      if (_pulseCtrl.isAnimating) _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  /// Цвет цифр процента и stage-name по светофору прогресса.
  /// Совместимо с HTML `getTL(p)` (line 294).
  Color _percentColor(int p) {
    if (p >= 70) return const Color(0xFF059669);
    if (p >= 40) return const Color(0xFFD97706);
    if (p >= 15) return const Color(0xFFDC2626);
    return AppColors.brand;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.percent.clamp(0, 100);
    final scale = widget.size / kHouseSize.width;
    final sceneW = kHouseSize.width * scale;
    final sceneH = kHouseSize.height * scale;
    final pColor = _percentColor(p);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_pulseCtrl, _bounceCtrl]),
          builder: (context, _) {
            return Transform.scale(
              scale: _bounceCtrl.isAnimating || _bounceCtrl.isCompleted
                  ? _bounceScale.value
                  : 1.0,
              child: SizedBox(
                width: sceneW,
                height: sceneH,
                child: ClipRect(
                  child: Stack(
                    children: [
                      // Sky background.
                      Positioned.fill(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 1200),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: p >= 100
                                  ? const [
                                      Color(0xFFDEE5EF),
                                      Color(0xFFC8D2E0),
                                      Color(0xFFB8C4D6),
                                    ]
                                  : const [
                                      Color(0xFFE8EDF5),
                                      Color(0xFFDDE3EE),
                                      Color(0xFFD5DBE8),
                                    ],
                              stops: const [0, 0.6, 1],
                            ),
                          ),
                        ),
                      ),

                      // Glow при 100% — мягкий зелёный круг под домом.
                      if (p >= 100)
                        Positioned.fill(
                          child: Center(
                            child: SizedBox(
                              width: sceneW * 0.85,
                              height: sceneW * 0.85,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFF10B981).withValues(
                                        alpha: 0.10 + 0.10 * _pulseCtrl.value,
                                      ),
                                      const Color(0x0010B981),
                                    ],
                                    stops: const [0, 0.7],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Ground.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 36 * scale,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFBFC8D4),
                                Color(0xFFAEB8C6),
                              ],
                            ),
                            border: Border(
                              top: BorderSide(color: Color(0x0F000000)),
                            ),
                          ),
                        ),
                      ),

                      // Дом — фиксированная координатная система 220×240,
                      // центрируется и масштабируется через Transform.scale.
                      Center(
                        child: SizedBox(
                          width: kHouseSize.width,
                          height: kHouseSize.height,
                          child: Transform.scale(
                            scale: scale,
                            child: SizedBox(
                              width: kHouseSize.width,
                              height: kHouseSize.height,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  HouseFoundation(visible: p >= 10),
                                  HouseSocle(visible: p >= 20),
                                  HouseWalls1F(visible: p >= 33),
                                  HouseCeiling(visible: p >= 44),
                                  HouseWalls2F(visible: p >= 55),
                                  HouseRafters(visible: p >= 65),
                                  HouseRoof(visible: p >= 75),
                                  HouseFacade(visible: p >= 87),
                                  HouseWindows(visible: p >= 95),
                                  if (p >= 100) const HouseSparkles(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Процент + label
        const SizedBox(height: AppSpacing.x10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w900,
                  fontSize: 36,
                  letterSpacing: -2,
                  color: pColor,
                ),
                child: Text('$p%'),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(width: AppSpacing.x8),
                Flexible(
                  child: Text(
                    widget.subtitle!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.n400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
