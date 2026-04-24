import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// Базовое текстовое поле. Соответствует `.fi` из design-макетов:
/// высота 52, радиус 12, border n200 1.5px, focus=brand + glow,
/// error=red border+bg.
class AppInput extends StatefulWidget {
  const AppInput({
    required this.controller,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLength,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.textInputAction,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController controller;
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLength;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final bool autofocus;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final disabled = !widget.enabled;

    Color borderColor;
    Color backgroundColor;
    List<BoxShadow>? shadow;

    if (disabled) {
      borderColor = AppColors.n200;
      backgroundColor = AppColors.n100;
    } else if (hasError) {
      borderColor = AppColors.redDot;
      backgroundColor = AppColors.redBg;
    } else if (_focused) {
      borderColor = AppColors.brand;
      backgroundColor = AppColors.brandLight;
      shadow = const [
        BoxShadow(color: AppColors.brandGlow, blurRadius: 0, spreadRadius: 3),
      ];
    } else {
      borderColor = AppColors.n200;
      backgroundColor = AppColors.n0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.x6),
        ],
        AnimatedContainer(
          duration: AppDurations.fast,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.input,
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: shadow,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            enabled: widget.enabled,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            maxLength: widget.maxLength,
            maxLines: widget.maxLines,
            inputFormatters: widget.inputFormatters,
            textInputAction: widget.textInputAction,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            style: AppTextStyles.body.copyWith(color: AppColors.n800),
            cursorColor: AppColors.brand,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.n400),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.prefixIcon == null ? 16 : 8,
                vertical: 14,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              isDense: true,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.x6),
          Text(
            widget.errorText!,
            style: AppTextStyles.caption.copyWith(color: AppColors.redDot),
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: AppSpacing.x6),
          Text(widget.helperText!, style: AppTextStyles.caption),
        ],
      ],
    );
  }
}
