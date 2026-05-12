import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Тёмный градиент-блок (heroProfile) — фон Profile-hero и Welcome-screen.
///
/// Берёт SafeArea сверху, добавляет contentPadding снизу 24, использует
/// прозрачный statusBar (icons light). Если нужен fullscreen — wrap-it
/// `extendBodyBehindAppBar: true` в Scaffold.
///
/// Содержит два декоративных radial-blob слоя (brand-glow слева вверху,
/// purple-glow справа внизу) для визуальной глубины — соответствует
/// CSS `radial-gradient` оверлеям из `design/Кластер_A___Профиль.html`.
class AppHeroHeader extends StatelessWidget {
  const AppHeroHeader({
    required this.child,
    this.gradient = AppGradients.heroProfile,
    this.bottomRadius = AppRadius.r28,
    this.contentPadding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
    this.decorativeBlobs = true,
    super.key,
  });

  final Widget child;
  final LinearGradient gradient;
  final double bottomRadius;
  final EdgeInsets contentPadding;

  /// Декоративные radial-blob слои (brand + purple). По умолчанию `true`.
  /// Отключить, если нужен «плоский» hero без украшений.
  final bool decorativeBlobs;

  @override
  Widget build(BuildContext context) {
    // viewPadding (а не padding), чтобы статус-бар учитывался даже когда
    // hero лежит внутри ListView/CustomScrollView — те оборачивают детей в
    // MediaQuery.removePadding(removeTop: true), если ScrollView.padding.top == 0,
    // и обычный MediaQuery.padding.top становится нулевым.
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final radius = BorderRadius.only(
      bottomLeft: Radius.circular(bottomRadius),
      bottomRight: Radius.circular(bottomRadius),
    );
    // SizedBox(width: double.infinity) — иначе non-positioned ребёнок Stack'а
    // получает loose constraints и ужимается до intrinsic-ширины колонки,
    // прилипая к topStart (контент уезжает влево).
    final padded = SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          contentPadding.left,
          contentPadding.top + topInset,
          contentPadding.right,
          contentPadding.bottom,
        ),
        child: child,
      ),
    );

    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          children: [
            if (decorativeBlobs) ...const [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppGradients.heroBlobBrand,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppGradients.heroBlobPurple,
                    ),
                  ),
                ),
              ),
            ],
            padded,
          ],
        ),
      ),
    );
  }
}
