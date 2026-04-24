import 'package:flutter/material.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// Унифицированный экран — AppBar + контент + опциональный bottom bar.
/// Все экраны приложения строятся поверх этого виджета.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.backgroundColor,
    this.showBack = false,
    this.onBack,
    this.safeTop = true,
    this.safeBottom = true,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget body;
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottom;
  final Color? backgroundColor;
  final bool showBack;
  final VoidCallback? onBack;
  final bool safeTop;
  final bool safeBottom;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final hasAppBar = title != null || showBack || actions != null;

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.n50,
      appBar: hasAppBar
          ? AppBar(
              title: title == null ? null : Text(title!),
              titleTextStyle: AppTextStyles.h1,
              leading: leading ??
                  (showBack
                      ? IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                          ),
                          onPressed:
                              onBack ?? () => Navigator.of(context).maybePop(),
                        )
                      : null),
              actions: actions,
            )
          : null,
      body: SafeArea(
        top: safeTop,
        bottom: safeBottom,
        child: Padding(padding: padding, child: body),
      ),
      bottomNavigationBar: bottom,
    );
  }
}
