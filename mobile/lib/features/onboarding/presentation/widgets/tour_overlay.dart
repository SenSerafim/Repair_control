import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/tour_anchor_registry.dart';
import '../../application/tour_controller.dart';
import '../../domain/tour_step.dart';

/// Полно-экранный overlay поверх обычного содержимого тура.
///
/// Дизайн под лучшие практики interactive walkthrough (Slack / Notion / Duolingo):
/// 1. Spotlight-cutout с пульсирующим золотым glow вокруг кнопки.
/// 2. Анимированный «палец» (`touch_app`) в центре cutout, пульсирует scale.
/// 3. Bubble-tooltip рядом с кнопкой с треугольной стрелкой, указывающей на неё.
/// 4. Smooth Tween анимация при смене подсвечиваемого элемента — cutout
///    плавно «перелетает» с одной кнопки на другую.
/// 5. Auto-scroll: если anchor за viewport-ом, через `Scrollable.ensureVisible`
///    подкручиваем underlying-список так, чтобы кнопка стала видна.
///
/// Если на текущем экране anchor-а нет (info-step типа Welcome / Completion
/// или экран не обернул кнопку в `TourAnchor`) — overlay переходит в
/// info-mode: затемнённый фон + bubble по центру.
class TourOverlay extends ConsumerStatefulWidget {
  const TourOverlay({
    required this.activeScreenKey,
    required this.bubbleBuilder,
    super.key,
  });

  /// Какой экран сейчас на стеке. `TourShell` передаёт это значение.
  /// Если оно не совпадает с `currentStep.screenKey` — overlay не рисует.
  final String activeScreenKey;

  /// Бабл строится снаружи, чтобы overlay не зависел от l10n.
  final Widget Function(BuildContext, TourStep step) bubbleBuilder;

  @override
  ConsumerState<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends ConsumerState<TourOverlay>
    with TickerProviderStateMixin {
  Rect? _previousRect;
  Rect? _targetRect;
  String? _lastAnchorId;
  TourAnchorRegistry? _subscribedRegistry;
  late final AnimationController _glowCtrl;
  late final AnimationController _fingerCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _fingerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _subscribedRegistry?.removeListener(_onRegistryChanged);
    _glowCtrl.dispose();
    _fingerCtrl.dispose();
    super.dispose();
  }

  void _ensureRegistrySubscription() {
    final registry = ref.read(tourAnchorRegistryProvider);
    if (identical(registry, _subscribedRegistry)) return;
    _subscribedRegistry?.removeListener(_onRegistryChanged);
    _subscribedRegistry = registry..addListener(_onRegistryChanged);
  }

  void _onRegistryChanged() {
    // Регистрация TourAnchor завершилась — перерисовываемся, чтобы
    // _resolveAnchorRect нашёл новый rect.
    //
    // notifyListeners часто вызывается ВО ВРЕМЯ build-фазы (TourAnchor.didChangeDependencies
    // → register → notify). Прямой setState в этот момент → assert
    // "setState() called during build". Откладываем на следующий кадр.
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  /// Опрашивает реестр на каждом фрейме (post-frame), пока anchor не
  /// смонтируется (после navigate underlying-screen ещё «прогревается»).
  /// При первом получении rect — запускаем auto-scroll и обновляем target.
  ///
  /// При смене шага НЕ зачищаем `_targetRect` сразу, чтобы не было
  /// мерцания «cutout исчез → бабл в центре → снова cutout». Старый rect
  /// показывается, пока новый anchor не смонтируется, потом TweenAnimationBuilder
  /// плавно перелетает.
  void _resolveAnchorRect(String? anchorId) {
    if (anchorId != _lastAnchorId) {
      _previousRect = _targetRect;
      _lastAnchorId = anchorId;
    }
    if (anchorId == null) {
      // Info-mode (welcome / completion) — нет cutout-а вообще.
      if (_targetRect != null) {
        setState(() => _targetRect = null);
      }
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final registry = ref.read(tourAnchorRegistryProvider);
      final rect = registry.rectOf(anchorId);
      if (rect == null || rect == _targetRect) return;
      _ensureAnchorVisible(registry.keyOf(anchorId));
      setState(() => _targetRect = rect);
    });
  }

  void _ensureAnchorVisible(GlobalKey? key) {
    if (key == null) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    final scrollable = Scrollable.maybeOf(ctx);
    if (scrollable == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tourControllerProvider);
    final step = state.current;

    if (step.screenKey != widget.activeScreenKey) {
      return const SizedBox.shrink();
    }

    _ensureRegistrySubscription();
    _resolveAnchorRect(step.anchorId);

    final target = _targetRect;
    return Positioned.fill(
      // Opaque: overlay поглощает все pointer-события. Иначе тап по
      // подсвеченной кнопке сработает в реальном экране и уведёт пользователя
      // из `/tour` через `context.push(...)`. Бабл-кнопки получают события
      // через нормальный hit-test внутри Stack.
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (target != null && target.contains(event.position)) {
            _onCutoutTap();
          }
        },
        // TweenAnimationBuilder требует non-null end. Когда rect ещё не
        // получен (info-шаги или anchor не смонтирован) — рендерим без
        // тween-а, чтобы не падать на ассерте.
        child: target == null
            ? _buildContent(step, null)
            : TweenAnimationBuilder<Rect?>(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                tween: RectTween(
                  begin: _previousRect ?? target,
                  end: target,
                ),
                builder: (ctx, animatedRect, _) =>
                    _buildContent(step, animatedRect),
              ),
      ),
    );
  }

  Widget _buildContent(TourStep step, Rect? rect) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _BackdropPainter(cutout: rect, glow: _glowCtrl),
        ),
        if (rect != null)
          _PulsingFinger(rect: rect, controller: _fingerCtrl),
        _BubbleWithArrow(
          cutout: rect,
          child: widget.bubbleBuilder(context, step),
        ),
      ],
    );
  }

  void _onCutoutTap() {
    ref.read(tourControllerProvider.notifier).advance();
  }
}

// ─────────── Backdrop + cutout + glow ───────────

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({required this.cutout, required this.glow})
      : super(repaint: glow);

  final Rect? cutout;
  final Animation<double> glow;

  static const Color _backdropColor = Color(0xCC0D1229);
  static const Color _glowColor = Color(0x66F59E0B);

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    if (cutout == null) {
      canvas.drawRect(fullRect, Paint()..color = _backdropColor);
      return;
    }
    final padded = cutout!.inflate(8);
    final rrect = RRect.fromRectAndRadius(padded, const Radius.circular(14));

    // Backdrop с прозрачным «отверстием» под cutout.
    canvas
      ..saveLayer(fullRect, Paint())
      ..drawRect(fullRect, Paint()..color = _backdropColor)
      ..drawRRect(rrect, Paint()..blendMode = BlendMode.clear)
      ..restore();

    // Пульсирующий glow вокруг cutout.
    final pulse = 0.5 + glow.value * 0.5;
    final glowPaint = Paint()
      ..color = _glowColor.withValues(alpha: 0.45 * pulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 16 + 6 * pulse);
    final ringPaint = Paint()
      ..color = _glowColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas
      ..drawRRect(rrect, glowPaint)
      ..drawRRect(rrect, ringPaint);
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.cutout != cutout || old.glow != glow;
}

// ─────────── Pulsing tap-here finger ───────────

class _PulsingFinger extends StatelessWidget {
  const _PulsingFinger({required this.rect, required this.controller});

  final Rect rect;
  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    // 36px-кружок с touch-иконкой по центру cutout.
    const size = 44.0;
    return Positioned(
      left: rect.center.dx - size / 2,
      top: rect.center.dy - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            final scale = 1.0 + 0.18 * controller.value;
            final opacity = 0.85 + 0.15 * (1 - controller.value);
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(0xFFF59E0B)
                            .withValues(alpha: 0.5 * controller.value),
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.touch_app_rounded,
                    color: Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────── Bubble + connecting arrow ───────────

class _BubbleWithArrow extends StatelessWidget {
  const _BubbleWithArrow({required this.cutout, required this.child});

  final Rect? cutout;
  final Widget child;

  /// Минимальный отступ bubble от cutout.
  static const double _gap = 14;

  /// Максимальная ширина bubble.
  static const double _maxWidth = 380;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final padding = media.padding;

    if (cutout == null) {
      // Info-mode: bubble по центру с подложкой-фоном.
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: child,
          ),
        ),
      );
    }

    // Решаем, разместить bubble выше или ниже cutout.
    final spaceAbove = cutout!.top - padding.top - _gap;
    final spaceBelow = screen.height - cutout!.bottom - padding.bottom - _gap;
    final placeBelow = spaceBelow >= spaceAbove;

    // Горизонтальное центрирование стрелки относительно cutout.
    final arrowCenterX = cutout!.center.dx.clamp(48.0, screen.width - 48.0);

    return Positioned(
      left: 16,
      right: 16,
      top: placeBelow ? cutout!.bottom + _gap : null,
      bottom: placeBelow ? null : screen.height - cutout!.top + _gap,
      child: Align(
        alignment: placeBelow ? Alignment.topCenter : Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (placeBelow)
                _Arrow(
                  pointDown: false,
                  arrowCenterX: arrowCenterX - 16,
                ),
              child,
              if (!placeBelow)
                _Arrow(
                  pointDown: true,
                  arrowCenterX: arrowCenterX - 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.pointDown, required this.arrowCenterX});

  final bool pointDown;

  /// Глобальная X-координата центра стрелки. Используется для смещения
  /// внутри ограниченной по ширине Column-обёртки.
  final double arrowCenterX;

  @override
  Widget build(BuildContext context) {
    // Позиционируем треугольник по горизонтали через Align с фактором,
    // вычисленным из MediaQuery.size.width.
    final width = MediaQuery.of(context).size.width - 32; // padding 16+16
    final centerOffset = arrowCenterX - width / 2;
    final alignmentX = (centerOffset / (width / 2)).clamp(-1.0, 1.0);
    return SizedBox(
      width: width,
      height: 10,
      child: Align(
        alignment: Alignment(alignmentX, 0),
        child: SizedBox(
          width: 22,
          height: 10,
          child: CustomPaint(
            painter: _ArrowPainter(pointDown: pointDown),
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.pointDown});

  final bool pointDown;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final shadow = Paint()
      ..color = const Color(0x1A0D1229)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final path = Path();
    if (pointDown) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close();
    } else {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..close();
    }
    canvas
      ..drawPath(path, shadow)
      ..drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.pointDown != pointDown;
}
