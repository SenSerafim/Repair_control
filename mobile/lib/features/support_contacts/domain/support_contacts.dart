/// Контакты поддержки, настраиваемые из админки и доступные через
/// `GET /api/me/app-settings`. Пустые поля скрываются на UI — мы не
/// показываем плейсхолдеры или «не задано».
class SupportContacts {
  const SupportContacts({
    this.maxUrl,
    this.vkUrl,
    this.telegramUrl,
    this.email,
    this.phone,
  });

  /// MAX (мессенджер) — https-ссылка, открывается в браузере.
  final String? maxUrl;

  /// VK — https://vk.com/... либо https://vk.me/...
  final String? vkUrl;

  /// Telegram — оставлен для backward compat (поле было до S18).
  final String? telegramUrl;

  /// Email — открывается через mailto:
  final String? email;

  /// Телефон в международном формате (+7…). Открывается через tel:
  final String? phone;

  bool get isEmpty =>
      _isBlank(maxUrl) &&
      _isBlank(vkUrl) &&
      _isBlank(telegramUrl) &&
      _isBlank(email) &&
      _isBlank(phone);

  static String? _normalize(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool _isBlank(String? value) => value == null || value.isEmpty;

  /// Парсер Map<String, String> из `getAppSettings()`. Алиас
  /// `support_telegram_url` (был до S18) маппится в [telegramUrl].
  static SupportContacts fromAppSettings(Map<String, String> settings) {
    return SupportContacts(
      maxUrl: _normalize(settings['support_max_url']),
      vkUrl: _normalize(settings['support_vk_url']),
      telegramUrl: _normalize(settings['support_telegram_url']),
      email: _normalize(settings['support_email']),
      phone: _normalize(settings['support_phone']),
    );
  }
}
