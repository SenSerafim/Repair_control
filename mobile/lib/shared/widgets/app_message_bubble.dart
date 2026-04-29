import 'package:flutter/material.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// Сообщение в чате — incoming/outgoing с асимметричными радиусами
/// (4px на углу-хвостике) согласно дизайну `Кластер F` chat-conversation.
///
/// CSS-spec:
/// - max-width: 75% контейнера
/// - padding: 10px (v) × 14px (h)
/// - font: 14px / weight 600 / line-height 1.5
/// - border-radius: r16 везде, кроме «хвостика» (4px)
/// - outgoing: gradient `bubbleOut` + white text + bottomRight=4
/// - incoming: n0 + n200 border + n800 text + bottomLeft=4
///
/// Опционально:
/// - [senderLabel] — имя отправителя (для group/project chat), font 11/700,
///   цвет [senderColor].
/// - [time] — мини-таймстамп внутри bubble, font 10/600 opacity 0.6.
/// - [editedMark] — добавляет «(изм.)» рядом со временем.
/// - [forwardedLabel] — текст «Переслано» сверху bubble.
class AppMessageBubble extends StatelessWidget {
  const AppMessageBubble({
    required this.text,
    required this.isMine,
    this.onLongPress,
    this.onTap,
    this.italic = false,
    this.dimmed = false,
    this.senderLabel,
    this.senderColor,
    this.time,
    this.editedMark = false,
    this.forwardedLabel,
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

  final String? senderLabel;
  final Color? senderColor;
  final String? time;
  final bool editedMark;
  final String? forwardedLabel;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fg = isMine ? AppColors.n0 : AppColors.n800;
    final secondaryFg = isMine
        ? AppColors.n0.withValues(alpha: 0.65)
        : AppColors.n400;
    return Opacity(
      opacity: dimmed ? 0.7 : 1,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(maxWidth: width * 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMine ? null : AppColors.n0,
            gradient: isMine ? AppGradients.bubbleOut : null,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (forwardedLabel != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shortcut_rounded, size: 12, color: secondaryFg),
                    const SizedBox(width: 4),
                    Text(
                      forwardedLabel!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: secondaryFg,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (senderLabel != null) ...[
                Text(
                  senderLabel!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: senderColor ?? AppColors.brand,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                text,
                style: AppTextStyles.body.copyWith(
                  color: fg,
                  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                  height: 1.5,
                ),
              ),
              if (time != null) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (editedMark) ...[
                      Text(
                        '(изм.)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: secondaryFg,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      time!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: secondaryFg,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
