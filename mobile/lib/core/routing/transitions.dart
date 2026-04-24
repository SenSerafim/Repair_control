import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Кастомные переходы между экранами под Material3 + дизайн-макеты.
///
/// Использование:
/// ```dart
/// GoRoute(
///   path: '/projects/:id',
///   pageBuilder: slideLeftPage((ctx, state) => ConsoleScreen(id: ...)),
/// )
/// ```
typedef PageBuilder = Widget Function(
  BuildContext context,
  GoRouterState state,
);

/// Slide-from-right + fade — стандартный переход «вперёд».
GoRouterPageBuilder slideLeftPage(PageBuilder builder) {
  return (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: builder(context, state),
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, anim, secondary, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          ));
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(position: slide, child: child),
          );
        },
      );
}

/// Slide-from-bottom — для «модальных» full-screen экранов
/// (камера, photo-picker, upload).
GoRouterPageBuilder slideUpPage(PageBuilder builder) {
  return (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: builder(context, state),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (context, anim, secondary, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          ));
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(position: slide, child: child),
          );
        },
      );
}

/// Pure fade — нейтральный кросс-фейд.
GoRouterPageBuilder fadePage(PageBuilder builder) {
  return (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: builder(context, state),
        transitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      );
}
