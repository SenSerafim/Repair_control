import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Декоративный префикс RU-телефона: 🇷🇺 +7 + вертикальный разделитель.
/// Подставляется в `AppInput.prefixIcon`. Сам в контроллер ничего не пишет —
/// в текстовом поле хранится только 10 локальных цифр (см. `PhoneInputFormatter`).
class RuPhonePrefix extends StatelessWidget {
  const RuPhonePrefix({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🇷🇺', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          const Text(
            '+7',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.n700,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 22, color: AppColors.n200),
        ],
      ),
    );
  }
}
