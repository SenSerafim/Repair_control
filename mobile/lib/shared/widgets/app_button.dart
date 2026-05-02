import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

enum AppButtonVariant {
  primary,
  secondary,
  ghost,
  destructive,
  success,
  /// Белая на тёмном фоне (Welcome): brand-цвет текста.
  white,
  /// Прозрачная с белой обводкой (Welcome secondary).
  outlineWhite,
  /// Ghost-кнопка с красной обводкой (Tool Detail «Удалить инструмент»).
  ghostDanger,
}

enum AppButtonSize { lg, sm }

/// Базовая кнопка приложения.
/// Варианты из design/Кластер *.html: .btn-blue, .btn-white, .btn-ghost,
/// .btn-danger, .btn-success. Размеры: lg=54, sm=40.
class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.lg,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    super.key,
  });

  final String label;

  /// Обработчик тапа. Может быть синхронным (`() { ... }`) или асинхронным
  /// (`() async { ... }` / возвращающим `Future`). Если возвращает `Future`,
  /// кнопка автоматически дисейблится до его завершения и показывает
  /// спиннер — это устраняет spam-tap (юзер жмёт 4 раза → 4 одинаковых
  /// POST → 409 storm). Для синхронных хендлеров действует короткий
  /// debounce, чтобы двойной тап не отправлял два запроса подряд.
  final FutureOr<void> Function()? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;
  bool _busy = false;
  DateTime? _lastTap;

  static const _syncDebounce = Duration(milliseconds: 350);

  bool get _enabled =>
      widget.onPressed != null && !widget.isLoading && !_busy;

  @override
  Widget build(BuildContext context) {
    final height = widget.size == AppButtonSize.lg ? 54.0 : 40.0;
    final textStyle = widget.size == AppButtonSize.lg
        ? AppTextStyles.button
        : AppTextStyles.buttonSm;

    final spec = _specFor(widget.variant, enabled: _enabled);

    final opacity = _pressed && _enabled ? 0.9 : 1.0;
    final scale = _pressed && _enabled ? 0.97 : 1.0;
    final showSpinner = widget.isLoading || _busy;

    final child = Container(
      height: height,
      width: widget.fullWidth ? double.infinity : null,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: widget.size == AppButtonSize.lg ? 24 : 16,
      ),
      decoration: BoxDecoration(
        color: spec.background,
        gradient: spec.gradient,
        borderRadius: AppRadius.buttonSm,
        border: spec.border,
        boxShadow: _enabled ? spec.shadow : null,
      ),
      child: showSpinner
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(spec.textColor),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: spec.textColor),
                  const SizedBox(width: AppSpacing.x8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    style: textStyle.copyWith(color: spec.textColor),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
    );

    return GestureDetector(
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel:
          _enabled ? () => setState(() => _pressed = false) : null,
      onTap: _enabled ? _handleTap : null,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: AppDurations.fast,
        child: AnimatedScale(
          scale: scale,
          duration: AppDurations.fast,
          child: child,
        ),
      ),
    );
  }

  Future<void> _handleTap() async {
    final cb = widget.onPressed;
    if (cb == null || _busy) return;
    final now = DateTime.now();
    final last = _lastTap;
    if (last != null && now.difference(last) < _syncDebounce) {
      return;
    }
    _lastTap = now;
    final result = cb();
    if (result is Future<void>) {
      setState(() => _busy = true);
      try {
        await result;
      } catch (_) {
        // Ошибки сетевого слоя обрабатываются вызывающей стороной
        // (тосты / провайдеры). Кнопка обязана разблокироваться в любом
        // случае, поэтому исключение проглатываем здесь и не пробрасываем.
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  static _ButtonSpec _specFor(AppButtonVariant v, {required bool enabled}) {
    if (!enabled) {
      return const _ButtonSpec(
        background: AppColors.n100,
        textColor: AppColors.n400,
      );
    }
    switch (v) {
      case AppButtonVariant.primary:
        return const _ButtonSpec(
          gradient: LinearGradient(
            colors: [Color(0xFF5B7EF8), AppColors.brandDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          textColor: AppColors.n0,
          shadow: AppShadows.shBlue,
        );
      case AppButtonVariant.secondary:
        return _ButtonSpec(
          background: AppColors.n0,
          textColor: AppColors.brand,
          border: Border.all(color: AppColors.n200, width: 1.5),
        );
      case AppButtonVariant.ghost:
        return _ButtonSpec(
          background: AppColors.brandLight,
          textColor: AppColors.brand,
          border: Border.all(color: AppColors.brandLight),
        );
      case AppButtonVariant.destructive:
        return const _ButtonSpec(
          background: AppColors.redBg,
          textColor: AppColors.redText,
          shadow: AppShadows.shRed,
        );
      case AppButtonVariant.success:
        return const _ButtonSpec(
          background: AppColors.greenDark,
          textColor: AppColors.n0,
          shadow: AppShadows.shGreen,
        );
      case AppButtonVariant.white:
        return const _ButtonSpec(
          background: AppColors.n0,
          textColor: AppColors.brand,
        );
      case AppButtonVariant.outlineWhite:
        return _ButtonSpec(
          background: Colors.transparent,
          textColor: AppColors.n0,
          border: Border.all(color: AppColors.n0, width: 1.5),
        );
      case AppButtonVariant.ghostDanger:
        return _ButtonSpec(
          background: AppColors.n0,
          textColor: AppColors.redText,
          border: Border.all(color: AppColors.redDot, width: 1.5),
        );
    }
  }
}

class _ButtonSpec {
  const _ButtonSpec({
    required this.textColor,
    this.background,
    this.gradient,
    this.border,
    this.shadow,
  });

  final Color textColor;
  final Color? background;
  final Gradient? gradient;
  final Border? border;
  final List<BoxShadow>? shadow;
}
