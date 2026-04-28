import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Тёмный градиент-блок (heroProfile) — фон Profile-hero и Welcome-screen.
///
/// Берёт SafeArea сверху, добавляет contentPadding снизу 24, использует
/// прозрачный statusBar (icons light). Если нужен fullscreen — wrap-it
/// `extendBodyBehindAppBar: true` в Scaffold.
class AppHeroHeader extends StatelessWidget {
  const AppHeroHeader({
    required this.child,
    this.gradient = AppGradients.heroProfile,
    this.bottomRadius = AppRadius.r28,
    this.contentPadding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
    super.key,
  });

  final Widget child;
  final LinearGradient gradient;
  final double bottomRadius;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(bottomRadius),
          bottomRight: Radius.circular(bottomRadius),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        contentPadding.left,
        contentPadding.top + topInset,
        contentPadding.right,
        contentPadding.bottom,
      ),
      child: child,
    );
  }
}
