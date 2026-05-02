import 'package:flutter/material.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// Унифицированный экран — AppBar + контент + опциональный bottom bar.
/// Все экраны приложения строятся поверх этого виджета.
class AppScaffold extends StatefulWidget {
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
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _backInFlight = false;

  /// Защита от двойного тапа по back-кнопке: пока кадр с pop не отрисован,
  /// повторные тапы Navigator.maybePop ловят assert `!_debugLocked` и роняют
  /// весь стек. Гард снимаем только в следующем post-frame.
  void _handleBack() {
    if (_backInFlight) return;
    _backInFlight = true;
    try {
      final cb = widget.onBack;
      if (cb != null) {
        cb();
      } else {
        Navigator.of(context).maybePop();
      }
    } catch (_) {
      // Navigator может бросить assert если стек уже в transition —
      // молча проглатываем, защищая UI от краха.
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _backInFlight = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAppBar =
        widget.title != null || widget.showBack || widget.actions != null;

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? AppColors.n50,
      appBar: hasAppBar
          ? AppBar(
              title: widget.title == null ? null : Text(widget.title!),
              titleTextStyle: AppTextStyles.h1,
              leading: widget.leading ??
                  (widget.showBack
                      ? IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                          ),
                          onPressed: _backInFlight ? null : _handleBack,
                        )
                      : null),
              actions: widget.actions,
            )
          : null,
      body: SafeArea(
        top: widget.safeTop,
        bottom: widget.safeBottom,
        child: Padding(padding: widget.padding, child: widget.body),
      ),
      bottomNavigationBar: widget.bottom,
    );
  }
}
