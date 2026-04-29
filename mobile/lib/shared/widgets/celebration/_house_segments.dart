import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 9 архитектурных слоёв дома + sparkles.
///
/// Координатная система — 220×240 (как в `design/house_animation.html`).
/// Все позиции в долях от 220×240, клиенты должны размещать сегменты
/// внутри `Stack` с этими размерами и применять `Transform.scale` для
/// масштабирования.
///
/// Каждый слой — `Positioned` с `Container`/`ClipPath` и заранее
/// заданным `BoxDecoration`. `visible: bool` управляет fade+slide-up
/// анимацией появления (450ms cubic-bezier).
///
/// `Positioned` должен быть прямым ребёнком `Stack`, поэтому
/// AnimatedOpacity/AnimatedSlide живут ВНУТРИ Positioned, обёртывая
/// контент-`child`.

const Size kHouseSize = Size(220, 240);

const Duration _kFadeDuration = Duration(milliseconds: 450);
const Curve _kFadeCurve = Curves.easeOutBack;
const Offset _kHiddenOffset = Offset(0, 0.4);

Widget _fadeIn({required bool visible, required Widget child}) {
  return AnimatedOpacity(
    duration: _kFadeDuration,
    opacity: visible ? 1 : 0,
    child: AnimatedSlide(
      duration: _kFadeDuration,
      curve: _kFadeCurve,
      offset: visible ? Offset.zero : _kHiddenOffset,
      child: child,
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────
// 1. Foundation (s-fnd) — th: 10%
// ──────────────────────────────────────────────────────────────────────

class HouseFoundation extends StatelessWidget {
  const HouseFoundation({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 16,
      right: 16,
      height: 18,
      child: _fadeIn(
        visible: visible,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF9CA3AF), Color(0xFF838B98)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                offset: Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 2,
              child: ColoredBox(color: Color(0x1AFFFFFF)),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// 2. Socle (s-socle) — th: 20%
// ──────────────────────────────────────────────────────────────────────

class HouseSocle extends StatelessWidget {
  const HouseSocle({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 18,
      left: 12,
      right: 12,
      height: 8,
      child: _fadeIn(
        visible: visible,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFB0B7C3), Color(0xFFA0A8B4)],
            ),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 1,
              child: ColoredBox(color: Color(0x1FFFFFFF)),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// 3. Walls 1F (s-w1) — th: 33%
// ──────────────────────────────────────────────────────────────────────

class HouseWalls1F extends StatelessWidget {
  const HouseWalls1F({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 26,
      left: 20,
      right: 20,
      height: 64,
      child: _fadeIn(
        visible: visible,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF0EDE8), Color(0xFFE6E2DA)],
            ),
            border: Border(
              top: BorderSide(color: Color(0x0A000000)),
              left: BorderSide(color: Color(0x0A000000)),
              right: BorderSide(color: Color(0x0A000000)),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// 4. Ceiling (s-ceil) — th: 44%
// ──────────────────────────────────────────────────────────────────────

class HouseCeiling extends StatelessWidget {
  const HouseCeiling({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 90,
      left: 16,
      right: 16,
      height: 6,
      child: _fadeIn(
        visible: visible,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFBFC8D4), Color(0xFFAEB8C6)],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// 5. Walls 2F (s-w2) — th: 55%
// ──────────────────────────────────────────────────────────────────────

class HouseWalls2F extends StatelessWidget {
  const HouseWalls2F({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 96,
      left: 20,
      right: 20,
      height: 54,
      child: _fadeIn(
        visible: visible,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF0EDE8), Color(0xFFE6E2DA)],
            ),
            border: Border(
              top: BorderSide(color: Color(0x0A000000)),
              left: BorderSide(color: Color(0x0A000000)),
              right: BorderSide(color: Color(0x0A000000)),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// 6. Rafters (s-raft) — th: 65%
// ──────────────────────────────────────────────────────────────────────

class HouseRafters extends StatelessWidget {
  const HouseRafters({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 150,
      left: 6,
      right: 6,
      height: 12,
      child: _fadeIn(
        visible: visible,
        child: ClipPath(
          clipper: _TriangleClipper(),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8E96A4), Color(0xFF7E8694)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// 7. Roof (s-roof) — th: 75%
// ──────────────────────────────────────────────────────────────────────

class HouseRoof extends StatelessWidget {
  const HouseRoof({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 150,
      left: 0,
      right: 0,
      height: 48,
      child: _fadeIn(
        visible: visible,
        child: ClipPath(
          clipper: _TriangleClipper(),
          child: Stack(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF5C6B80), Color(0xFF475569)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x14000000),
                      offset: Offset(0, -2),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 4,
                right: 4,
                top: 3,
                bottom: 0,
                child: ClipPath(
                  clipper: _TriangleClipper(),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF64748B), Color(0xFF4F5D72)],
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
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

// ──────────────────────────────────────────────────────────────────────
// 8. Facade (s-facade) — th: 87%
// ──────────────────────────────────────────────────────────────────────

class HouseFacade extends StatelessWidget {
  const HouseFacade({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    const lineColor = Color(0x09000000);
    return Positioned(
      bottom: 26,
      left: 20,
      right: 20,
      height: 124,
      child: _fadeIn(
        visible: visible,
        child: const IgnorePointer(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 8,
                right: 8,
                top: 16,
                height: 1,
                child: ColoredBox(color: lineColor),
              ),
              Positioned(
                left: 8,
                right: 8,
                top: 34,
                height: 1,
                child: ColoredBox(color: lineColor),
              ),
              Positioned(
                left: 8,
                right: 8,
                top: 78,
                height: 1,
                child: ColoredBox(color: lineColor),
              ),
              Positioned(
                left: 8,
                right: 8,
                top: 96,
                height: 1,
                child: ColoredBox(color: lineColor),
              ),

              // Door surround (light frame).
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _CenteredBox(
                  width: 30,
                  height: 40,
                  color: Color(0xFF969DAA),
                ),
              ),

              // Door body.
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _Door(),
              ),

              // Door lintel.
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: _CenteredBox(
                  width: 34,
                  height: 3,
                  color: Color(0xFFB0B7C3),
                  radius: 0.5,
                ),
              ),

              // Door step.
              Positioned(
                bottom: -2,
                left: 0,
                right: 0,
                child: _CenteredBox(
                  width: 36,
                  height: 3,
                  color: Color(0xFF969DAA),
                  radius: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Door extends StatelessWidget {
  const _Door();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 38,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6B5A46), Color(0xFF52422F)],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 3,
                left: 2,
                child: _DoorPanel(width: 9, height: 14),
              ),
              Positioned(
                top: 3,
                right: 2,
                child: _DoorPanel(width: 9, height: 14),
              ),
              Positioned(
                bottom: 4,
                left: 2,
                child: _DoorPanel(width: 9, height: 13),
              ),
              Positioned(
                bottom: 4,
                right: 2,
                child: _DoorPanel(width: 9, height: 13),
              ),
              Positioned(
                right: 4,
                top: 19,
                child: _DoorKnob(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenteredBox extends StatelessWidget {
  const _CenteredBox({
    required this.width,
    required this.height,
    required this.color,
    this.radius = 2,
  });

  final double width;
  final double height;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
          ),
        ),
      ),
    );
  }
}

class _DoorPanel extends StatelessWidget {
  const _DoorPanel({required this.width, required this.height});
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        color: Color(0x0F000000),
        borderRadius: BorderRadius.all(Radius.circular(1)),
      ),
    );
  }
}

class _DoorKnob extends StatelessWidget {
  const _DoorKnob();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: Color(0xFFA8B0BC),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// 9. Windows + chimney + smoke (s-winch) — th: 95%
// ──────────────────────────────────────────────────────────────────────

class HouseWindows extends StatelessWidget {
  const HouseWindows({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 240,
      child: _fadeIn(
        visible: visible,
        child: const IgnorePointer(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Chimney.
              Positioned(
                top: 52,
                right: 55,
                width: 14,
                height: 26,
                child: _Chimney(),
              ),
              // Smoke.
              Positioned(
                top: 26,
                right: 55,
                width: 14,
                height: 26,
                child: _Smoke(),
              ),

              // 2F windows.
              _Window(left: 38, top: 104, width: 32, height: 24),
              _WindowLintel(left: 36, top: 101, width: 36),
              _WindowSill(left: 36, top: 129, width: 36),

              _Window(left: 150, top: 104, width: 32, height: 24),
              _WindowLintel(left: 148, top: 101, width: 36),
              _WindowSill(left: 148, top: 129, width: 36),

              // 1F windows.
              _Window(left: 38, top: 168, width: 32, height: 26),
              _WindowLintel(left: 36, top: 165, width: 36),
              _WindowSill(left: 36, top: 195, width: 36),

              _Window(left: 150, top: 168, width: 32, height: 26),
              _WindowLintel(left: 148, top: 165, width: 36),
              _WindowSill(left: 148, top: 195, width: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _Window extends StatelessWidget {
  const _Window({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFC5D3E0),
                    Color(0xFFA8BDCF),
                    Color(0xFF90A8BE),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF969DAA),
                  width: 1.5,
                ),
              ),
            ),
            // Vertical mullion.
            Positioned(
              left: width / 2 - 0.5,
              top: 0,
              bottom: 0,
              width: 1,
              child: const ColoredBox(color: Color(0x59FFFFFF)),
            ),
            // Horizontal mullion.
            Positioned(
              left: 0,
              right: 0,
              top: height / 2 - 0.5,
              height: 1,
              child: const ColoredBox(color: Color(0x59FFFFFF)),
            ),
            // Reflection highlight.
            const Positioned(
              top: 2,
              left: 2,
              width: 5,
              height: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowLintel extends StatelessWidget {
  const _WindowLintel({
    required this.left,
    required this.top,
    required this.width,
  });
  final double left;
  final double top;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: 2.5,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFFB0B7C3),
          borderRadius: BorderRadius.all(Radius.circular(0.5)),
        ),
      ),
    );
  }
}

class _WindowSill extends StatelessWidget {
  const _WindowSill({
    required this.left,
    required this.top,
    required this.width,
  });
  final double left;
  final double top;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: 2.5,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFF969DAA),
          borderRadius: BorderRadius.all(Radius.circular(0.5)),
        ),
      ),
    );
  }
}

class _Chimney extends StatelessWidget {
  const _Chimney();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      clipBehavior: Clip.none,
      children: [
        // Body.
        Positioned(
          left: 0,
          top: 4,
          width: 14,
          height: 22,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8B7355), Color(0xFF6E5B42)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(1),
                topRight: Radius.circular(1),
              ),
            ),
          ),
        ),
        // Cap.
        Positioned(
          left: -2,
          top: 0,
          width: 18,
          height: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFF7B6B4A),
              borderRadius: BorderRadius.all(Radius.circular(0.5)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Дым из трубы — 2 точки, бесконечно поднимающиеся вверх и
/// растворяющиеся.
class _Smoke extends StatelessWidget {
  const _Smoke();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      clipBehavior: Clip.none,
      children: [
        _SmokeParticle(
          delay: Duration.zero,
          duration: Duration(milliseconds: 3000),
          size: 7,
          startX: 3,
        ),
        _SmokeParticle(
          delay: Duration(milliseconds: 1000),
          duration: Duration(milliseconds: 3500),
          size: 5,
          startX: 7,
        ),
      ],
    );
  }
}

class _SmokeParticle extends StatelessWidget {
  const _SmokeParticle({
    required this.delay,
    required this.duration,
    required this.size,
    required this.startX,
  });

  final Duration delay;
  final Duration duration;
  final double size;
  final double startX;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: startX,
      bottom: 0,
      child: SizedBox(
        width: 16,
        height: 26,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0x0A000000),
            shape: BoxShape.circle,
          ),
        )
            .animate(
              onPlay: (c) => c.repeat(),
              delay: delay,
            )
            .fadeIn(duration: const Duration(milliseconds: 100))
            .move(
              begin: Offset.zero,
              end: const Offset(-5, -24),
              duration: duration,
              curve: Curves.linear,
            )
            .scale(
              begin: const Offset(0.4, 0.4),
              end: const Offset(1.1, 1.1),
              duration: duration,
            )
            .fadeOut(
              begin: 0.5,
              delay: duration ~/ 2,
              duration: duration ~/ 2,
            ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Sparkles (s-wow) — рендерится при 100%
// ──────────────────────────────────────────────────────────────────────

class HouseSparkles extends StatelessWidget {
  const HouseSparkles({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            for (final spec in _sparkleSpecs)
              Positioned(
                left: spec.cx - 3,
                top: spec.cy - 3,
                width: 6,
                height: 6,
                child: _Sparkle(
                  baseRadius: spec.r,
                  maxRadius: spec.maxR,
                  delay: spec.delay,
                  duration: spec.duration,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SparkleSpec {
  const _SparkleSpec({
    required this.cx,
    required this.cy,
    required this.r,
    required this.maxR,
    required this.delay,
    required this.duration,
  });
  final double cx;
  final double cy;
  final double r;
  final double maxR;
  final Duration delay;
  final Duration duration;
}

const _sparkleSpecs = <_SparkleSpec>[
  _SparkleSpec(
    cx: 15,
    cy: 80,
    r: 1,
    maxR: 3,
    delay: Duration.zero,
    duration: Duration(milliseconds: 1800),
  ),
  _SparkleSpec(
    cx: 205,
    cy: 75,
    r: 1,
    maxR: 3,
    delay: Duration(milliseconds: 400),
    duration: Duration(milliseconds: 2000),
  ),
  _SparkleSpec(
    cx: 25,
    cy: 200,
    r: 0.8,
    maxR: 2.5,
    delay: Duration(milliseconds: 700),
    duration: Duration(milliseconds: 2200),
  ),
  _SparkleSpec(
    cx: 195,
    cy: 205,
    r: 0.8,
    maxR: 2.5,
    delay: Duration(milliseconds: 1000),
    duration: Duration(milliseconds: 1600),
  ),
];

class _Sparkle extends StatelessWidget {
  const _Sparkle({
    required this.baseRadius,
    required this.maxRadius,
    required this.delay,
    required this.duration,
  });
  final double baseRadius;
  final double maxRadius;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: maxRadius * 2,
        height: maxRadius * 2,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0x66FFFFFF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x66FFFFFF),
                blurRadius: 3,
                spreadRadius: 1,
              ),
            ],
          ),
        )
            .animate(
              onPlay: (c) => c.repeat(reverse: true),
              delay: delay,
            )
            .scale(
              begin: Offset(baseRadius / maxRadius, baseRadius / maxRadius),
              end: const Offset(1, 1),
              duration: duration,
              curve: Curves.easeInOut,
            ),
      ),
    );
  }
}
