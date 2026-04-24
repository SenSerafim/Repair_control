import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// 6-значный PIN-инпут. Соответствует `.pin-box` из design-макетов:
/// 56×64, radius 16, border 2px n200. Filled → brand-border + brand-light-bg.
/// Cursor blink 1s.
class PinInput extends StatefulWidget {
  const PinInput({
    required this.length,
    required this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.errorText,
    this.autofocus = true,
    super.key,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final bool enabled;
  final String? errorText;
  final bool autofocus;

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  late final TextEditingController _controller = TextEditingController();
  late final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _focus.requestFocus());
    }
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final v = _controller.text;
    widget.onChanged(v);
    if (v.length == widget.length) widget.onCompleted?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final hasError =
        widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 64,
          child: Stack(
            children: [
              // Скрытое реальное поле для ввода.
              Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  autofillHints: const [AutofillHints.oneTimeCode],
                ),
              ),
              // Видимые ячейки.
              GestureDetector(
                onTap: () => _focus.requestFocus(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(widget.length, (i) {
                    final char = i < _controller.text.length
                        ? _controller.text[i]
                        : '';
                    final isFocused =
                        _focus.hasFocus && i == _controller.text.length;
                    final isFilled = char.isNotEmpty;
                    return _PinCell(
                      char: char,
                      focused: isFocused,
                      filled: isFilled,
                      error: hasError,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.x8),
          Text(
            widget.errorText!,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.redDot),
          ),
        ],
      ],
    );
  }
}

class _PinCell extends StatelessWidget {
  const _PinCell({
    required this.char,
    required this.focused,
    required this.filled,
    required this.error,
  });

  final String char;
  final bool focused;
  final bool filled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    Color border;
    Color bg;
    if (error) {
      border = AppColors.redDot;
      bg = AppColors.redBg;
    } else if (focused) {
      border = AppColors.brand;
      bg = AppColors.brandLight;
    } else if (filled) {
      border = AppColors.brand;
      bg = AppColors.brandLight;
    } else {
      border = AppColors.n200;
      bg = AppColors.n0;
    }

    return AnimatedContainer(
      duration: AppDurations.fast,
      width: 48,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.card,
        border: Border.all(color: border, width: 2),
      ),
      child: focused && char.isEmpty
          ? const _BlinkingCursor()
          : Text(
              char,
              style: AppTextStyles.h1.copyWith(
                color: error ? AppColors.redText : AppColors.n800,
              ),
            ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.3).animate(_ctrl),
      child: Container(
        width: 2,
        height: 28,
        color: AppColors.brand,
      ),
    );
  }
}
