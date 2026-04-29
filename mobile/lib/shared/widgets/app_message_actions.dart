import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Action-row под message-bubble (forward).
///
/// Дизайн `Кластер F` (`f-chat-project`): row из квадратных 28×28 кнопок
/// с n200 border, radius 8. В оригинальном дизайне было три кнопки
/// (👍 👎 ↗) — лайк/дизлайк убраны (нет на бекенде, решение пользователя).
class AppMessageActions extends StatelessWidget {
  const AppMessageActions({
    required this.onForward,
    this.alignToRight = false,
    super.key,
  });

  final VoidCallback onForward;
  final bool alignToRight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        mainAxisAlignment:
            alignToRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          _ActionBtn(
            icon: Icons.reply_outlined,
            tooltip: 'Переслать',
            onTap: onForward,
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: AppDurations.fast,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _pressed ? AppColors.n100 : AppColors.n0,
              border: Border.all(color: AppColors.n200, width: 1),
              borderRadius: BorderRadius.circular(AppRadius.r8),
            ),
            alignment: Alignment.center,
            child: Transform.flip(
              flipX: true,
              child: Icon(widget.icon, size: 14, color: AppColors.n500),
            ),
          ),
        ),
      ),
    );
  }
}
