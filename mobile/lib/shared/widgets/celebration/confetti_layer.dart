import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Слой процедурного конфетти.
///
/// Создаёт `particleCount` частиц, каждая летит сверху вниз
/// (translateY 0→`fallDistance`) с одновременным поворотом 720° и
/// исчезновением в последние 20% жизни. Палитра — 12 цветов
/// (HTML 368).
///
/// [waves] — сколько волн запустить. Каждая волна сдвинута на 800ms,
/// чтобы салют казался плотным.
class ConfettiLayer extends StatefulWidget {
  const ConfettiLayer({
    this.particleCount = 100,
    this.waves = 3,
    this.fallDistance = 900,
    this.minDurationMs = 2000,
    this.maxDurationMs = 3800,
    this.onCompleted,
    super.key,
  });

  final int particleCount;
  final int waves;
  final double fallDistance;
  final int minDurationMs;
  final int maxDurationMs;
  final VoidCallback? onCompleted;

  @override
  State<ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<ConfettiLayer> {
  static const _palette = <Color>[
    Color(0xFF34D399),
    Color(0xFF10B981),
    Color(0xFF059669),
    Color(0xFF4F6EF7),
    Color(0xFF3A56D4),
    Color(0xFF64748B),
    Color(0xFF94A3B8),
    Color(0xFF818CF8),
    Color(0xFF6366F1),
    Color(0xFFA78BFA),
    Color(0xFFF59E0B),
    Color(0xFFFBBF24),
  ];

  final _rng = math.Random();
  late final List<_ParticleSpec> _particles;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      widget.particleCount * widget.waves,
      _spec,
    );

    final maxLife = widget.maxDurationMs +
        (widget.waves - 1) * 800 +
        1200; // launch delay + duration
    Future.delayed(
      Duration(milliseconds: maxLife + 400),
      () {
        if (mounted) widget.onCompleted?.call();
      },
    );
  }

  _ParticleSpec _spec(int i) {
    final waveIdx = i ~/ widget.particleCount;
    final wavePhase = waveIdx * 800; // ms
    return _ParticleSpec(
      leftPercent: _rng.nextDouble(),
      size: 4 + _rng.nextDouble() * 10,
      color: _palette[_rng.nextInt(_palette.length)],
      circle: _rng.nextBool(),
      delayMs: wavePhase + (_rng.nextDouble() * 1200).round(),
      durationMs: widget.minDurationMs +
          _rng.nextInt(widget.maxDurationMs - widget.minDurationMs),
      startRotation: _rng.nextDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final fall = constraints.maxHeight.isFinite
              ? constraints.maxHeight + 40
              : widget.fallDistance;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (final p in _particles)
                Positioned(
                  left: p.leftPercent * w,
                  top: -p.size,
                  child: _Particle(spec: p, fallDistance: fall),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ParticleSpec {
  const _ParticleSpec({
    required this.leftPercent,
    required this.size,
    required this.color,
    required this.circle,
    required this.delayMs,
    required this.durationMs,
    required this.startRotation,
  });

  final double leftPercent;
  final double size;
  final Color color;
  final bool circle;
  final int delayMs;
  final int durationMs;
  final double startRotation;
}

class _Particle extends StatelessWidget {
  const _Particle({required this.spec, required this.fallDistance});

  final _ParticleSpec spec;
  final double fallDistance;

  @override
  Widget build(BuildContext context) {
    final shape = Container(
      width: spec.size,
      height: spec.size,
      decoration: BoxDecoration(
        color: spec.color.withValues(alpha: 0.85),
        shape: spec.circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: spec.circle ? null : BorderRadius.circular(1),
      ),
    );

    final delay = Duration(milliseconds: spec.delayMs);
    final duration = Duration(milliseconds: spec.durationMs);

    return shape
        .animate(delay: delay)
        .move(
          begin: Offset.zero,
          end: Offset(0, fallDistance),
          duration: duration,
          curve: Curves.linear,
        )
        .rotate(
          begin: spec.startRotation,
          end: spec.startRotation + 2,
          duration: duration,
          curve: Curves.linear,
        )
        .fadeOut(
          delay: Duration(milliseconds: (spec.durationMs * 0.8).round()),
          duration: Duration(milliseconds: (spec.durationMs * 0.2).round()),
        );
  }
}
