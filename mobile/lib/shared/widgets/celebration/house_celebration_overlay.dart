import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'confetti_layer.dart';

/// Однократный full-screen WOW-салют, показываемый при достижении
/// проектом 100% прогресса.
///
/// Состав: glow (пульсирующее радиальное сияние), shimmer (диагональный
/// блик), banner «✓ Дом построен!» (spring entrance) и `ConfettiLayer`
/// сверху всего. Self-dismiss через 6 сек или по тапу.
class HouseCelebrationOverlay {
  HouseCelebrationOverlay._();

  /// Показывает overlay поверх всего экрана.
  ///
  /// Безопасно вызывать несколько раз — повторные вызовы игнорируются,
  /// пока активен предыдущий overlay.
  static void show(BuildContext context, {String? message}) {
    if (_currentEntry != null) return;

    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CelebrationOverlay(
        message: message ?? '✓ Дом построен!',
        onDismiss: () {
          if (entry.mounted) entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  /// Принудительно убрать активный overlay (при выходе с экрана).
  static void dismiss() {
    final entry = _currentEntry;
    if (entry != null && entry.mounted) {
      entry.remove();
    }
    _currentEntry = null;
  }

  static OverlayEntry? _currentEntry;
}

class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay> {
  bool _fadingOut = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), _startFadeOut);
  }

  void _startFadeOut() {
    if (!mounted || _fadingOut) return;
    setState(() => _fadingOut = true);
    Future.delayed(const Duration(milliseconds: 600), widget.onDismiss);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _startFadeOut,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 600),
          opacity: _fadingOut ? 0 : 1,
          child: IgnorePointer(
            ignoring: _fadingOut,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Лёгкое осветление сцены
                const _SceneShimmer(),

                // Радиальный glow в центре
                const Center(child: _CelebrationGlow()),

                // Конфетти
                const Positioned.fill(
                  child: ConfettiLayer(
                    particleCount: 80,
                    waves: 3,
                  ),
                ),

                // Banner «✓ Дом построен!»
                Center(child: _CelebrationBanner(message: widget.message)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Полупрозрачный диагональный блик, бегущий по сцене 2 сек, infinite.
class _SceneShimmer extends StatelessWidget {
  const _SceneShimmer();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [0.3, 0.5, 0.7],
              colors: [
                Color(0x00FFFFFF),
                Color(0x33FFFFFF),
                Color(0x00FFFFFF),
              ],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .slideX(
              begin: -1.5,
              end: 1.5,
              duration: const Duration(seconds: 2),
              curve: Curves.linear,
            ),
      ),
    );
  }
}

/// Радиальное мягкое сияние под центром.
class _CelebrationGlow extends StatelessWidget {
  const _CelebrationGlow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 320,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0x4010B981), Color(0x0010B981)],
            stops: [0, 0.7],
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
          )
          .fadeIn(
            begin: 0.6,
            duration: const Duration(milliseconds: 300),
          ),
    );
  }
}

/// Pill-banner с зелёным градиентом и spring-entrance.
class _CelebrationBanner extends StatelessWidget {
  const _CelebrationBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF10B981)],
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59059669),
            blurRadius: 40,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0x26FFFFFF), width: 2),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w900,
          fontSize: 17,
          letterSpacing: -0.3,
          color: Colors.white,
        ),
      ),
    )
        .animate(delay: const Duration(milliseconds: 300))
        .scaleXY(
          begin: 0.7,
          end: 1,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
        )
        .fadeIn(
          duration: const Duration(milliseconds: 700),
        )
        .moveY(
          begin: -20,
          end: 0,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
        );
  }
}
