import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Стабильная палитра аватара — выбирается по hash от seed (`userId`
/// или `name`), 5 вариантов из дизайна `Кластер F` (chat-avatar):
/// blue / green / yellow / purple / grey.
///
/// Все палитры — `linear-gradient(135deg, start, end)`.
enum AvatarPalette {
  blue,
  green,
  yellow,
  purple,
  grey;

  (Color, Color) get colors => switch (this) {
        AvatarPalette.blue => (AppColors.brand, AppColors.brandDark),
        AvatarPalette.green => (AppColors.greenDot, AppColors.greenDark),
        AvatarPalette.yellow => (AppColors.yellowDot, AppColors.yellowText),
        AvatarPalette.purple => (AppColors.purple, AppColors.purple),
        AvatarPalette.grey => (AppColors.n500, AppColors.n700),
      };

  /// Стабильно выбрать палитру по [seed] (userId / name / id).
  /// Чистая функция — те же входные данные дают тот же результат.
  static AvatarPalette fromSeed(String? seed) {
    if (seed == null || seed.isEmpty) return AvatarPalette.grey;
    final h = seed.hashCode.abs();
    return values[h % values.length];
  }
}

/// Универсальный аватар — gradient initials или фото.
///
/// Дизайн: `Кластер F` chat-avatar (48x48), `Кластер A` profile-avatar (60x60).
/// Используется в: payment-card, chat-bubble, chats-list, team, approvals,
/// notifications.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.seed,
    this.name,
    this.imageUrl,
    this.size = 40,
    this.palette,
    super.key,
  });

  /// Источник для расчёта градиента (userId/id). Если name пустое — берём
  /// первый символ seed как fallback инициала.
  final String seed;

  /// Полное имя пользователя — используется для генерации инициалов.
  final String? name;

  /// Если задан — отображается фото вместо инициалов (с фоном-градиентом
  /// как fallback при загрузке/ошибке).
  final String? imageUrl;

  final double size;

  /// Если явно передана — переопределяет hash-выбор. Используется для
  /// семантических аватаров (например, role-coloured tile).
  final AvatarPalette? palette;

  @override
  Widget build(BuildContext context) {
    final p = palette ?? AvatarPalette.fromSeed(seed);
    final (a, b) = p.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [a, b],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      // Backend в `/api/me` возвращает relative S3-key (e.g. "avatar/abc.png").
      // Без http(s)://-префикса NetworkImage парсит как `file:///avatar/...`
      // и кидает ArgumentError каждый кадр (бесконечный цикл рендера).
      // Пока backend не отдаёт presigned URL — рисуем initials, если URL
      // не absolute. Когда будет готов S3-resolver — здесь префикс apiBaseUrl.
      foregroundDecoration: _isAbsoluteUrl(imageUrl)
          ? BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              ),
            )
          : null,
      child: _isAbsoluteUrl(imageUrl)
          ? const SizedBox.shrink()
          : Text(
              _initials(),
              style: TextStyle(
                color: AppColors.n0,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.36,
                letterSpacing: -0.3,
              ),
            ),
    );
  }

  String _initials() {
    final raw = (name?.isNotEmpty ?? false) ? name! : seed;
    final cleaned = raw
        .split(RegExp(r'[\s_\-]+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
    if (cleaned.isNotEmpty) return cleaned;
    final fallback = raw.replaceAll(RegExp('[^A-Za-zА-Яа-я0-9]'), '');
    if (fallback.isEmpty) return '?';
    return fallback.substring(0, 1).toUpperCase();
  }

  static bool _isAbsoluteUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }
}
