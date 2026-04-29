import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Sticky bottom action-bar — `.action-bar` из `design/Кластер D`.
///
/// Белый фон, верхняя 1px-граница `n200`, внутренний padding 16/12/16,
/// SafeArea для iPhone home-indicator. Принимает 1–N кнопок-чилдов с
/// настраиваемым `flex` (1:1 — Approve/Reject; 1:2 — «Отклонить план»/
/// «Принять план» в `d-plan-approval`).
class AppActionBar extends StatelessWidget {
  const AppActionBar({
    required this.children,
    this.flexes,
    this.gap = AppSpacing.x10,
    this.stacked = false,
    super.key,
  }) : assert(
          flexes == null || flexes.length == children.length,
          'flexes must match children length',
        );

  final List<Widget> children;
  final List<int>? flexes;
  final double gap;

  /// Если true — кнопки идут вертикально (используется когда у одной из
  /// кнопок длинный label или их > 2).
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.n0,
        border: Border(top: BorderSide(color: AppColors.n200)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x12,
        AppSpacing.x16,
        AppSpacing.x16,
      ),
      child: SafeArea(
        top: false,
        child: stacked || children.length == 1
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _withGaps(children, gap),
              )
            : Row(children: _withFlex(children, flexes, gap)),
      ),
    );
  }

  static List<Widget> _withGaps(List<Widget> items, double gap) {
    if (items.length < 2) return items;
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i < items.length - 1) out.add(SizedBox(height: gap));
    }
    return out;
  }

  static List<Widget> _withFlex(
    List<Widget> items,
    List<int>? flexes,
    double gap,
  ) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(Expanded(flex: flexes?[i] ?? 1, child: items[i]));
      if (i < items.length - 1) out.add(SizedBox(width: gap));
    }
    return out;
  }
}
