import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Системное сообщение в чате — серая пилюля по центру.
///
/// Дизайн `Кластер F` (`f-chat-conversation`, `f-chat-project`).
/// CSS-spec: padding 4×16, radius pill, bg n100, text 11/600/n400.
/// Поддерживает emoji-префиксы для специальных событий
/// (📋 заявка, ✅ одобрение, ⚠️ доп. работа, 💰 выплата).
class AppSystemMessage extends StatelessWidget {
  const AppSystemMessage({
    required this.text,
    this.tone = AppSystemMessageTone.neutral,
    super.key,
  });

  final String text;
  final AppSystemMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(tone);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.fg,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum AppSystemMessageTone {
  neutral,
  success,
  warning,
  info,
  payment,
}

class _SysColors {
  const _SysColors(this.bg, this.fg);
  final Color bg;
  final Color fg;
}

_SysColors _resolveColors(AppSystemMessageTone tone) {
  switch (tone) {
    case AppSystemMessageTone.success:
      return const _SysColors(AppColors.greenLight, AppColors.greenDark);
    case AppSystemMessageTone.warning:
      return const _SysColors(AppColors.yellowBg, AppColors.yellowText);
    case AppSystemMessageTone.info:
      return const _SysColors(AppColors.brandLight, AppColors.brand);
    case AppSystemMessageTone.payment:
      return const _SysColors(AppColors.purpleBg, AppColors.purple);
    case AppSystemMessageTone.neutral:
      return const _SysColors(AppColors.n100, AppColors.n400);
  }
}
