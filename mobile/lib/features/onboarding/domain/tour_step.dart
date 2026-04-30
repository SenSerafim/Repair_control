/// Один шаг интерактивного демо-тура.
///
/// `screenKey` — экран, на котором этот шаг показывается (`'console'`,
/// `'stages'`, …). Используется и `TourOverlay`, чтобы понять, нужно ли
/// сейчас рисовать backdrop, и `TourController`, чтобы знать, что после
/// тапа по `anchorId` пора переходить к следующему шагу.
///
/// `anchorId` — id `TourAnchor`-обёртки вокруг подсвечиваемой кнопки.
/// `null` означает информационный шаг (например, Welcome / Completion):
/// `TourOverlay` рисует только bubble, без spotlight, и единственная
/// кнопка прогресса — «Далее» внутри bubble.
///
/// `requiresUserTap` — если `true`, прогресс происходит только при тапе
/// по подсвеченному элементу. Если `false`, в bubble есть кнопка «Далее».
class TourStep {
  const TourStep({
    required this.id,
    required this.screenKey,
    required this.titleKey,
    required this.messageKey,
    this.anchorId,
    this.requiresUserTap = true,
    this.routeOnAdvance,
  });

  /// Стабильный id (для тестов и аналитики).
  final String id;

  /// Какой экран показывает этот шаг (`'welcome'`, `'console'`, `'stages'`,
  /// `'stage_detail'`, `'step_detail'`, `'approvals'`, `'approval_detail'`,
  /// `'budget'`, `'payments_list'`, `'materials'`, `'chats'`,
  /// `'chat_conversation'`, `'notifications'`, `'completion'`).
  final String screenKey;

  /// ID подсвечиваемой `TourAnchor` или `null` для информационных шагов.
  final String? anchorId;

  /// ARB-ключ для заголовка bubble.
  final String titleKey;

  /// ARB-ключ для тела bubble.
  final String messageKey;

  /// Если true — переход к следующему шагу только по тапу на anchor.
  /// Если false — в bubble показывается кнопка «Далее».
  final bool requiresUserTap;

  /// Если задан — после `advance()` контроллер делает GoRouter-переход
  /// на этот путь. Используется на информационных шагах (Welcome → Console),
  /// где anchor нет и пользователь жмёт «Далее» в bubble.
  final String? routeOnAdvance;
}
