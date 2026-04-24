import 'package:intl/intl.dart';

/// Форматирование денежных сумм.
///
/// Бекенд присылает int64 копейки (`workBudget`, `materialsBudget`) — мы
/// показываем их как «1 250 000 ₽». Никакого float-а.
class Money {
  const Money._();

  /// Non-breaking space, который intl добавляет как thousand-separator для
  /// ru_RU. Нормализуем к обычному пробелу для стабильности тестов.
  static const _nbsp = ' ';

  /// Форматирует сумму в копейках. По умолчанию — без дробей.
  static String format(
    int kopecks, {
    int decimals = 0,
    String currency = '₽',
    String locale = 'ru_RU',
  }) {
    final rubles = kopecks ~/ 100;
    final remainder = kopecks.remainder(100).abs();
    final integerFormatted = NumberFormat.decimalPattern(locale)
        .format(rubles)
        .replaceAll(_nbsp, ' ');
    final suffix = currency.isEmpty ? '' : ' $currency';
    if (decimals == 0) {
      return '$integerFormatted$suffix';
    }
    final frac = remainder.toString().padLeft(2, '0');
    return '$integerFormatted,$frac$suffix';
  }

  /// Парсит пользовательский ввод в копейки. Поддерживает:
  /// "1 250 000", "1 250 000 ₽", "1250000,50", "1 250,50".
  /// Возвращает null для пустой строки или мусора.
  static int? parseInputToKopecks(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final cleaned = trimmed
        .replaceAll(RegExp(r'[^\d,.]'), '')
        .replaceAll('.', ',');
    if (cleaned.isEmpty) return null;
    final parts = cleaned.split(',');
    final integerPart = parts[0];
    if (integerPart.isEmpty) return null;
    final integer = int.tryParse(integerPart);
    if (integer == null) return null;
    var fraction = 0;
    if (parts.length >= 2) {
      final f = parts[1];
      if (f.isNotEmpty) {
        final padded = f.padRight(2, '0').substring(0, 2);
        fraction = int.tryParse(padded) ?? 0;
      }
    }
    return integer * 100 + fraction;
  }
}
