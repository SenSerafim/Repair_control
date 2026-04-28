import 'package:flutter/material.dart';

/// Дизайн-токены Repair Control.
///
/// Источник: `design/Кластер *.html` (CSS variables) + ТЗ §4.
/// Запрещено использовать хардкод цветов/радиусов/теней где-либо кроме этого файла.
class AppColors {
  const AppColors._();

  // Бренд
  static const Color brand = Color(0xFF4F6EF7);
  static const Color brandDark = Color(0xFF3A56D4);
  static const Color brandLight = Color(0xFFEEF2FF);
  static const Color brandMid = Color(0xFF6B83F5);
  static const Color brandGlow = Color(0x2E4F6EF7); // 0.18 alpha

  // Светофор — зелёный
  static const Color greenDot = Color(0xFF10B981);
  static const Color greenDark = Color(0xFF059669);
  static const Color greenLight = Color(0xFFD1FAE5);

  // Светофор — жёлтый
  static const Color yellowDot = Color(0xFFF59E0B);
  static const Color yellowText = Color(0xFF92400E);
  static const Color yellowBg = Color(0xFFFEF3C7);

  // Светофор — красный
  static const Color redDot = Color(0xFFDC2626);
  static const Color redText = Color(0xFF991B1B);
  static const Color redBg = Color(0xFFFEE2E2);

  // Светофор — синий (informational)
  static const Color blueDot = Color(0xFF4F6EF7);
  static const Color blueText = Color(0xFF1E40AF);
  static const Color blueBg = Color(0xFFEEF2FF);

  // Акцент (согласования)
  static const Color purple = Color(0xFF6D28D9);
  static const Color purpleBg = Color(0xFFEDE9FE);

  // Нейтральная шкала
  static const Color n0 = Color(0xFFFFFFFF);
  static const Color n50 = Color(0xFFF8FAFF);
  static const Color n100 = Color(0xFFF1F4FD);
  static const Color n200 = Color(0xFFE4E9F7);
  static const Color n300 = Color(0xFFC9D2EE);
  static const Color n400 = Color(0xFF8E9BBF);
  static const Color n500 = Color(0xFF5F6E99);
  static const Color n600 = Color(0xFF3D4B70);
  static const Color n700 = Color(0xFF2A3357);
  static const Color n800 = Color(0xFF1A2240);
  static const Color n900 = Color(0xFF0D1229);

  // Системные (tints для overlay)
  static const Color overlayBackdrop = Color(0x73000000); // 0.45
  static const Color whiteGhost = Color(0x1AFFFFFF); // 0.1
}

/// Dark-палитра (Этап 7.5 ROAD_TO_100). Material 3 dark-инверсия brand-цвета,
/// контраст ≥4.5 для текста по WCAG AA. Используется через `Theme.of(context)`
/// или `themeMode == ThemeMode.dark` гейтом.
class AppColorsDark {
  const AppColorsDark._();

  // Бренд (тот же hue, повышенная яркость для тёмного фона)
  static const Color brand = Color(0xFF7C8FFF);
  static const Color brandDark = Color(0xFF5566D6);
  static const Color brandLight = Color(0xFF1E2440);
  static const Color brandMid = Color(0xFF8896F2);
  static const Color brandGlow = Color(0x4F7C8FFF);

  // Светофор зелёный
  static const Color greenDot = Color(0xFF34D399);
  static const Color greenDark = Color(0xFF10B981);
  static const Color greenLight = Color(0xFF052E16);

  // Светофор жёлтый
  static const Color yellowDot = Color(0xFFFCD34D);
  static const Color yellowText = Color(0xFFFEF3C7);
  static const Color yellowBg = Color(0xFF422006);

  // Светофор красный
  static const Color redDot = Color(0xFFF87171);
  static const Color redText = Color(0xFFFCA5A5);
  static const Color redBg = Color(0xFF450A0A);

  // Синий action
  static const Color blueDot = Color(0xFF7C8FFF);
  static const Color blueText = Color(0xFFBFCAFF);
  static const Color blueBg = Color(0xFF1E2440);

  // Purple
  static const Color purple = Color(0xFFA78BFA);
  static const Color purpleBg = Color(0xFF2E1065);

  // Нейтрали (инверсия n0..n900)
  static const Color n0 = Color(0xFF0D1229);
  static const Color n50 = Color(0xFF131836);
  static const Color n100 = Color(0xFF1A2240);
  static const Color n200 = Color(0xFF2A3357);
  static const Color n300 = Color(0xFF3D4B70);
  static const Color n400 = Color(0xFF5F6E99);
  static const Color n500 = Color(0xFF8E9BBF);
  static const Color n600 = Color(0xFFC9D2EE);
  static const Color n700 = Color(0xFFE4E9F7);
  static const Color n800 = Color(0xFFF1F4FD);
  static const Color n900 = Color(0xFFFFFFFF);

  static const Color overlayBackdrop = Color(0xB3000000);
  static const Color whiteGhost = Color(0x33FFFFFF);
}

class AppRadius {
  const AppRadius._();

  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
  static const double r28 = 28;
  static const double pill = 100;

  static BorderRadius all(double value) => BorderRadius.circular(value);

  static BorderRadius get card => BorderRadius.circular(r16);
  static BorderRadius get input => BorderRadius.circular(r12);
  static BorderRadius get buttonSm => BorderRadius.circular(r16);
  static BorderRadius get container => BorderRadius.circular(r20);
  static BorderRadius get bottomSheet => const BorderRadius.only(
        topLeft: Radius.circular(r28),
        topRight: Radius.circular(r28),
      );
}

class AppShadows {
  const AppShadows._();

  /// Лёгкая, для карточек списков.
  static const List<BoxShadow> sh1 = [
    BoxShadow(
      color: Color(0x0F0D1229), // rgba(13,18,41,0.06)
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color(0x124F6EF7), // rgba(79,110,247,0.07)
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  /// Средняя, для инпутов / elevated.
  static const List<BoxShadow> sh2 = [
    BoxShadow(
      color: Color(0x140D1229), // 0.08
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color(0x1A4F6EF7), // 0.10
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  /// Глубокая, для модалок и тостов.
  static const List<BoxShadow> sh3 = [
    BoxShadow(
      color: Color(0x1A0D1229), // 0.10
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
    BoxShadow(
      color: Color(0x244F6EF7), // 0.14
      offset: Offset(0, 16),
      blurRadius: 40,
    ),
  ];

  /// Бренд-тень под активные кнопки.
  static const List<BoxShadow> shBlue = [
    BoxShadow(
      color: Color(0x594F6EF7), // 0.35
      offset: Offset(0, 4),
      blurRadius: 20,
    ),
  ];

  /// Успех.
  static const List<BoxShadow> shGreen = [
    BoxShadow(
      color: Color(0x4D059669), // 0.30
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  /// Опасность.
  static const List<BoxShadow> shRed = [
    BoxShadow(
      color: Color(0x40DC2626), // 0.25
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  // ──────────────────────────────────────────────────────────────────
  // Glow-эффекты (дизайн `Кластер C/E`): мягкое сияние под active /
  // success / danger / 100%-complete состояниями. Без offset — равномерный
  // ореол. Используется на active step-checkbox, payment-amount, hero badges.
  // ──────────────────────────────────────────────────────────────────

  /// Зелёный glow — checked-checkbox, success-burst.
  static const List<BoxShadow> glowGreen = [
    BoxShadow(
      color: Color(0x4010B981), // rgba(16,185,129, 0.25)
      blurRadius: 12,
      spreadRadius: 1,
    ),
  ];

  /// Синий glow — focused input/active card, primary action.
  static const List<BoxShadow> glowBlue = [
    BoxShadow(
      color: Color(0x404F6EF7), // rgba(79,110,247, 0.25)
      blurRadius: 12,
      spreadRadius: 1,
    ),
  ];

  /// Жёлтый glow — paused-state, attention/warning.
  static const List<BoxShadow> glowYellow = [
    BoxShadow(
      color: Color(0x40F59E0B), // rgba(245,158,11, 0.25)
      blurRadius: 12,
      spreadRadius: 1,
    ),
  ];

  /// Красный glow — overdue/disputed status indicator.
  static const List<BoxShadow> glowRed = [
    BoxShadow(
      color: Color(0x40DC2626),
      blurRadius: 12,
      spreadRadius: 1,
    ),
  ];

  /// Золотой glow — 100%-complete (HouseProgress, StageDone celebration).
  static const List<BoxShadow> glowGold = [
    BoxShadow(
      color: Color(0x66F59E0B), // более яркий, alpha 0.4
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];
}

class AppSpacing {
  const AppSpacing._();

  static const double x2 = 2;
  static const double x4 = 4;
  static const double x6 = 6;
  static const double x8 = 8;
  static const double x10 = 10;
  static const double x12 = 12;
  static const double x14 = 14;
  static const double x16 = 16;
  static const double x20 = 20;
  static const double x24 = 24;
  static const double x32 = 32;
  static const double x40 = 40;

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: x16);
  static const EdgeInsets cardInset = EdgeInsets.all(x14);
  static const EdgeInsets bottomSheet =
      EdgeInsets.fromLTRB(x20, x14, x20, x40 + x4);
}

class AppDurations {
  const AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

/// Градиенты дизайна Cluster A (Welcome / Profile-hero / success-CTA / role-cards).
class AppGradients {
  const AppGradients._();

  /// Фон Welcome-экрана. 155° dark blue → brand.
  static const LinearGradient heroDark = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [
      Color(0xFF0F172A),
      Color(0xFF1E3A5F),
      Color(0xFF1D4ED8),
    ],
    stops: [0, 0.5, 1],
  );

  /// Hero-блок Профиля. 155° чуть светлее, чтобы аватар-инициалы читались.
  static const LinearGradient heroProfile = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [
      Color(0xFF0F172A),
      Color(0xFF1A2D5A),
      Color(0xFF2A3F7E),
    ],
    stops: [0, 0.5, 1],
  );

  /// Success-CTA / role-switched success (135°).
  static const LinearGradient successHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  /// Бренд-кнопка (135°).
  static const LinearGradient brandButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand, AppColors.brandDark],
  );

  /// 5 палитр для AppAvatar — соответствуют CSS g1-blue/g2-green/g3-purple/g4-yellow/g5-grey.
  static const LinearGradient avatarBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F6EF7), Color(0xFF3A56D4)],
  );

  static const LinearGradient avatarGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient avatarPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
  );

  static const LinearGradient avatarYellow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
  );

  static const LinearGradient avatarGrey = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
  );

  /// Маппинг seed → palette (для детерминированного выбора по userId / name).
  static LinearGradient avatarFor(int seed) {
    const palettes = [
      avatarBlue,
      avatarGreen,
      avatarPurple,
      avatarYellow,
      avatarGrey,
    ];
    return palettes[seed.abs() % palettes.length];
  }
}
