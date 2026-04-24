import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Локализованные форматтеры дат / времени / чисел / сумм.
///
/// Использует `Localizations.localeOf(context)` для получения локали.
/// Для российской по умолчанию — формат `ДД.ММ.ГГГГ`, время `HH:mm`,
/// числа с разделителем пробелом.
class Fmt {
  const Fmt._();

  static String date(BuildContext context, DateTime d) {
    final lang = Localizations.localeOf(context).languageCode;
    final pattern = lang == 'ru' ? 'dd.MM.yyyy' : 'MMM d, yyyy';
    return DateFormat(pattern, lang).format(d);
  }

  static String time(BuildContext context, DateTime d) {
    final lang = Localizations.localeOf(context).languageCode;
    return DateFormat('HH:mm', lang).format(d);
  }

  static String dateTime(BuildContext context, DateTime d) =>
      '${date(context, d)} · ${time(context, d)}';

  /// Форматирует int-целое число с разделителем тысяч.
  static String number(BuildContext context, int n) {
    final lang = Localizations.localeOf(context).languageCode;
    return NumberFormat.decimalPattern(lang).format(n);
  }

  /// Форматирует сумму в копейках как рубли с разделителем.
  /// Примеры: `1 250 000 ₽` (RU), `$1,250,000` (EN placeholder).
  static String money(BuildContext context, int kopecks) {
    final rub = kopecks ~/ 100;
    final lang = Localizations.localeOf(context).languageCode;
    final f = NumberFormat.decimalPattern(lang);
    return lang == 'ru' ? '${f.format(rub)} ₽' : '₽${f.format(rub)}';
  }

  /// Относительная дата («сегодня», «вчера», «N дней назад»).
  static String relative(BuildContext context, DateTime d) {
    final lang = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (lang == 'ru') {
      if (diff == 0) return 'сегодня';
      if (diff == 1) return 'вчера';
      if (diff < 7) return '$diff дн. назад';
      return date(context, d);
    } else {
      if (diff == 0) return 'today';
      if (diff == 1) return 'yesterday';
      if (diff < 7) return '$diff days ago';
      return date(context, d);
    }
  }
}
