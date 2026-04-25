import 'package:flutter/material.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// Сообщение в чате — incoming/outgoing с асимметричными радиусами
/// (4px на углу-хвостике) согласно дизайну `Кластер F` chat-conversation.
///
/// Точные размеры из CSS:
/// - max-width: 75% контейнера
/// - padding: 10px (v) × 14px (h)
/// - font: 14px / weight 600 / line-height 1.5
/// - border-radius: r16 везде, кроме «хвостика» (4px)
/// - outgoing: `#4F6EF7 + white text + bottomRight=4`
/// - incoming: `n0 + n200 border + n800 text + bottomLeft=4`
class AppMessageBubble extends StatelessWidget {
  const AppMessageBubble({
    required this.text,
    required this.isMine,
    this.onLongPress,
    this.onTap,
    this.italic = false,
    this.dimmed = false,
    super.key,
  });

  final String text;
  final bool isMine;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  /// Italic стиль текста — для удалённых сообщений «Сообщение удалено».
  final bool italic;

  /// Сниженная opacity — для удалённых сообщений.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bg = isMine ? AppColors.brand : AppColors.n0;
    final fg = isMine ? AppColors.n0 : AppColors.n800;
    return Opacity(
      opacity: dimmed ? 0.7 : 1,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(maxWidth: width * 0.75),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: isMine
                ? null
                : Border.all(color: AppColors.n200, width: 1),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.r16),
              topRight: const Radius.circular(AppRadius.r16),
              bottomLeft: Radius.circular(isMine ? AppRadius.r16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : AppRadius.r16),
            ),
          ),
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(
              color: fg,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
