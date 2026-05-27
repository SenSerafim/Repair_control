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

  /// Лёгкая, для карточек списков. 3-слойная: подложка + бренд-тинт +
  /// далёкая дымка — тактильная глубина без явных линий.
  static const List<BoxShadow> sh1 = [
    BoxShadow(
      color: Color(0x0A0D1229),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color(0x0D4F6EF7),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color(0x0A0D1229),
      offset: Offset(0, 8),
      blurRadius: 20,
    ),
  ];

  /// Средняя, для инпутов / elevated.
  static const List<BoxShadow> sh2 = [
    BoxShadow(
      color: Color(0x0F0D1229),
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
    BoxShadow(
      color: Color(0x1A4F6EF7),
      offset: Offset(0, 8),
      blurRadius: 22,
    ),
    BoxShadow(
      color: Color(0x0F0D1229),
      offset: Offset(0, 18),
      blurRadius: 40,
    ),
  ];

  /// Глубокая, для модалок и тостов.
  static const List<BoxShadow> sh3 = [
    BoxShadow(
      color: Color(0x1A0D1229),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
    BoxShadow(
      color: Color(0x294F6EF7),
      offset: Offset(0, 18),
      blurRadius: 38,
    ),
    BoxShadow(
      color: Color(0x1F0D1229),
      offset: Offset(0, 36),
      blurRadius: 72,
    ),
  ];

  /// Бренд-тень под активные кнопки. 2-слойная: насыщ. glow + ближняя тень.
  static const List<BoxShadow> shBlue = [
    BoxShadow(
      color: Color(0x6B4F6EF7),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
    BoxShadow(
      color: Color(0x384F6EF7),
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];

  /// Успех.
  static const List<BoxShadow> shGreen = [
    BoxShadow(
      color: Color(0x52059669),
      offset: Offset(0, 6),
      blurRadius: 20,
    ),
    BoxShadow(
      color: Color(0x2E059669),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  /// Опасность.
  static const List<BoxShadow> shRed = [
    BoxShadow(
      color: Color(0x47DC2626),
      offset: Offset(0, 6),
      blurRadius: 20,
    ),
    BoxShadow(
      color: Color(0x29DC2626),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  /// Тень под аватаром hero (двухслойная — насыщ. бренд + тёмная подложка).
  static const List<BoxShadow> avatarHero = [
    BoxShadow(
      color: Color(0x754F6EF7),
      offset: Offset(0, 12),
      blurRadius: 32,
    ),
    BoxShadow(
      color: Color(0x4D000000),
      offset: Offset(0, 4),
      blurRadius: 10,
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
    BoxShadow(color: Color(0x40DC2626), blurRadius: 12, spreadRadius: 1),
  ];

  /// Золотой glow — 100%-complete (HouseProgress, StageDone celebration).
  static const List<BoxShadow> glowGold = [
    BoxShadow(
      color: Color(0x66F59E0B), // более яркий, alpha 0.4
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  /// Двойное halo-кольцо вокруг success-circle (d-approved / result-screen).
  static const List<BoxShadow> haloGreen = [
    BoxShadow(color: Color(0x1A10B981), spreadRadius: 8),
    BoxShadow(color: Color(0x0D10B981), spreadRadius: 16),
    BoxShadow(
      color: Color(0x2E059669),
      offset: Offset(0, 12),
      blurRadius: 28,
    ),
  ];

  /// Двойное halo-кольцо вокруг error-circle (d-rejected).
  static const List<BoxShadow> haloRed = [
    BoxShadow(color: Color(0x1ADC2626), spreadRadius: 8),
    BoxShadow(color: Color(0x0DDC2626), spreadRadius: 16),
    BoxShadow(
      color: Color(0x2EDC2626),
      offset: Offset(0, 12),
      blurRadius: 28,
    ),
  ];

  // ──────────────────────────────────────────────────────────────────
  // Cluster E refresh — focus-ring, hover-tier, inset-highlight.
  // CSS-эквивалент: `--sh-glow: 0 0 0 4px rgba(79,110,247,0.10)`.
  // ──────────────────────────────────────────────────────────────────

  /// Brand focus-ring (мягкое 4px-кольцо без offset).
  /// Применяется на TextField / search-bar / card-press.
  static const List<BoxShadow> focusRingBlue = [
    BoxShadow(
      color: Color(0x1A4F6EF7), // alpha 0.10
      blurRadius: 0,
      spreadRadius: 4,
    ),
  ];

  /// Hover-tier тень — между sh1 и sh2 (карточки при press / hover).
  static const List<BoxShadow> shHover = [
    BoxShadow(
      color: Color(0x140D1229), // 0.08
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
    BoxShadow(
      color: Color(0x1F4F6EF7), // 0.12
      offset: Offset(0, 10),
      blurRadius: 26,
    ),
  ];

  /// Глубокая brand-подсветка — premium-кнопки в action-bar.
  static const List<BoxShadow> shBrandDeep = [
    BoxShadow(
      color: Color(0x664F6EF7), // 0.40
      offset: Offset(0, 6),
      blurRadius: 22,
      spreadRadius: -2,
    ),
  ];

  /// Цвет для имитации CSS inset-highlight (rgba(255,255,255,0.20))
  /// на иконках/баджах. Применяется как 1px top-border.
  static const Color innerHighlight = Color(0x33FFFFFF);

  // ──────────────────────────────────────────────────────────────────
  // Card surface — мягкая утончённая тень для карточек этапов и
  // строк чек-листа. Менее насыщенный голубой ореол, чем у `sh1`,
  // и чуть глубже — карточки «всплывают» из подложки.
  // Используется в StageStripeCard / StageRowCard / ChecklistStepRow /
  // StageStatsRow / TemplateCard.
  // ──────────────────────────────────────────────────────────────────
  static const List<BoxShadow> shCard = [
    BoxShadow(
      color: Color(0x0A0D1229), // rgba(13,18,41, 0.04)
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color(0x0F0D1229), // rgba(13,18,41, 0.06)
      offset: Offset(0, 4),
      blurRadius: 14,
    ),
  ];

  /// Мягкий зелёный halo для substep-точки 8×8 — мельче, чем
  /// [glowGreen]; не «забивает» соседний текст в плотных списках.
  static const List<BoxShadow> haloGreenSmall = [
    BoxShadow(
      color: Color(0x2310B981), // rgba(16,185,129, 0.14)
      blurRadius: 6,
      spreadRadius: 2,
    ),
  ];

  /// Brand-halo для inline-progress (4–5px бар).
  /// Тонкое сияние под цветной полоской прогресса этапа.
  static const List<BoxShadow> haloProgress = [
    BoxShadow(
      color: Color(0x4D4F6EF7), // rgba(79,110,247, 0.30)
      blurRadius: 8,
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
  static const EdgeInsets bottomSheet = EdgeInsets.fromLTRB(
    x20,
    x14,
    x20,
    x40 + x4,
  );
}

class AppDurations {
  const AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

/// Кастомные кривые анимаций — соответствуют CSS-easing из дизайн-референса
/// (`design/Кластер_A___Профиль.html`). Используются в `AnimatedContainer`,
/// `AnimatedScale`, transition'ах кнопок/чипов.
class AppCurves {
  const AppCurves._();

  /// Плавный «вылет», как `cubic-bezier(0.16, 1, 0.3, 1)`.
  /// Появление карточек, тостов, шторок.
  static const Cubic easeOut = Cubic(0.16, 1, 0.3, 1);

  /// Лёгкий «отскок», как `cubic-bezier(0.34, 1.56, 0.64, 1)`.
  /// Микро-нажатия: кнопки, чекбоксы, role-cards.
  static const Cubic spring = Cubic(0.34, 1.56, 0.64, 1);

  /// Material-soft, как `cubic-bezier(0.4, 0, 0.2, 1)` — Material Standard.
  /// Плавные смены цвета/border'а.
  static const Cubic soft = Cubic(0.4, 0, 0.2, 1);
}

/// Градиенты дизайна Cluster A (Welcome / Profile-hero / success-CTA / role-cards).
class AppGradients {
  const AppGradients._();

  /// Фон Welcome-экрана. 4-stop deep navy → brand с дополнительным
  /// тёмным акцентом сверху для большей тональной глубины.
  static const LinearGradient heroDark = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [
      Color(0xFF06091B),
      Color(0xFF0F172A),
      Color(0xFF13234A),
      Color(0xFF1D4ED8),
    ],
    stops: [0, 0.25, 0.65, 1],
  );

  /// Hero-блок Профиля. 4-stop: чуть светлее heroDark, чтобы аватар-
  /// инициалы читались; больше тональных переходов для богатства.
  static const LinearGradient heroProfile = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [
      Color(0xFF0B1024),
      Color(0xFF13193A),
      Color(0xFF1A2D5A),
      Color(0xFF2D45A0),
    ],
    stops: [0, 0.3, 0.65, 1],
  );

  /// Success-CTA / role-switched success (135°). 3-stop для глубины.
  static const LinearGradient successHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF047857)],
    stops: [0, 0.5, 1],
  );

  /// Бренд-кнопка (135°). 3-stop с осветлённым началом для glossy-эффекта.
  static const LinearGradient brandButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6A8AFF), AppColors.brand, AppColors.brandDark],
    stops: [0, 0.48, 1],
  );

  /// Premium 2-stop success-кнопка — для confirm / approved CTA
  /// (Cluster E: Подтвердить выплату / Закрыть спор / Сдать инструмент).
  static const LinearGradient successButtonHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF047857)],
  );

  /// Радиальный glow для hero-фона (накладывается поверх heroProfile/heroDark
  /// для создания эффекта «солнца» в верхнем-левом углу). Применяется в
  /// AppHeroHeader Stack-overlay.
  static const RadialGradient heroBlobBrand = RadialGradient(
    center: Alignment(-0.6, -1.2),
    radius: 1.1,
    colors: [Color(0x664F6EF7), Color(0x004F6EF7)],
    stops: [0, 1],
  );

  /// Дополнительный фиолетовый blob — второй уровень глубины hero
  /// (правый-нижний угол).
  static const RadialGradient heroBlobPurple = RadialGradient(
    center: Alignment(0.9, 1.2),
    radius: 1,
    colors: [Color(0x387C3AED), Color(0x007C3AED)],
    stops: [0, 1],
  );

  /// Plan-info-card в `d-plan-approval`: тёмный navy → brand.
  static const LinearGradient planInfo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A5F), AppColors.brand],
  );

  /// Plan-info-card rich: 3-stop brandDark → brand → brandMid (135°).
  /// Pending-approval баннер `d-plan-approval` и approval_detail _PlanBody.
  static const LinearGradient planInfoRich = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brandDark, AppColors.brand, AppColors.brandMid],
    stops: [0, 0.5, 1],
  );

  /// Soft brand-gradient для photo-плейсхолдеров (approval cards / detail).
  /// 135° brandLight → промежуточный → n300-tint, статичный shimmer.
  static const LinearGradient photoPlaceholder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brandLight, Color(0xFFDDE5FA), Color(0xFFC9D7F4)],
    stops: [0, 0.5, 1],
  );

  /// Question-карточка в `d-question-reply`: purple-light → purple-mid.
  static const LinearGradient questionPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.purpleBg, Color(0xFFDDD6FE)],
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

  /// Оранжевая палитра — 6-я для аватаров (используется в Cluster F:
  /// Сидоров В. в `f-chats`, deadlines/payment-warning notifications).
  static const LinearGradient avatarOrange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  /// Маппинг seed → palette (для детерминированного выбора по userId / name).
  static LinearGradient avatarFor(int seed) {
    const palettes = [
      avatarBlue,
      avatarGreen,
      avatarPurple,
      avatarYellow,
      avatarOrange,
      avatarGrey,
    ];
    return palettes[seed.abs() % palettes.length];
  }

  /// Outgoing message bubble (135°) — `f-chat-conversation` / `f-chat-project`.
  /// Чуть ярче `brandButton` для контраста с brand-text-buttons и input-кнопок.
  static const LinearGradient bubbleOut = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B7EF8), Color(0xFF3A56D4)],
  );

  // ──────────────────────────────────────────────────────────────────
  // Card surface — почти невидимый 180° градиент сверху-вниз. Делает
  // плоскость карточки чуть «живее» под ambient-светом экрана. Для
  // StageStripeCard / StageRowCard / ChecklistStepRow / StageStatsRow /
  // TemplateCard.
  // ──────────────────────────────────────────────────────────────────
  static const LinearGradient surfaceCard = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.n0, Color(0xFFFCFDFF)],
  );

  /// Слегка тёплый surface для активной строки чек-листа (вместо
  /// плоской заливки brandLight) — диагональ для лёгкого «свечения».
  static const LinearGradient activeStepBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5F8FF), AppColors.brandLight],
  );

  // Stripe-градиенты для верхней полоски карточек этапов
  // (StageStripeCard `::before`) и левой вертикальной полосы
  // (StageRowCard). Каждый соответствует Semaphore.
  static const LinearGradient stripeGreen = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF34D399), AppColors.greenDark],
  );
  static const LinearGradient stripeBrand = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.brandMid, AppColors.brand],
  );
  static const LinearGradient stripeYellow = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFCD34D), Color(0xFFD97706)],
  );
  static const LinearGradient stripeRed = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFF87171), AppColors.redDot],
  );
  static const LinearGradient stripePurple = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
  );

  /// Plan-stripe — слегка темнее, чтобы waiting-этапы не сливались с фоном.
  static const LinearGradient stripePlan = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.n200, AppColors.n300],
  );
}
