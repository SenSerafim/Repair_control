import 'package:flutter/services.dart';

/// Маска ввода RU-телефона: в контроллер пишутся только 10 локальных цифр
/// в формате `(XXX) XXX-XX-XX`. Префикс `+7` рисуется отдельно (см.
/// `RuPhonePrefix` в shared/widgets) и в значении контроллера не присутствует —
/// это убирает визуальную дубль-«+7 +7» и даёт WYSIWYG.
///
/// Paste-friendly: вставка `+7…`, `8…`, `7…` корректно усекается до локальных
/// 10 цифр.
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = _formatLocal(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String _onlyDigits(String s) => s.replaceAll(RegExp(r'\D'), '');

/// Нормализует произвольный ввод/вставку к 10 локальным RU-цифрам.
String _localDigits(String raw) {
  var digits = _onlyDigits(raw);
  // Срез leading 7/8 для строк вида `+79991234567` или `89991234567`.
  if (digits.length == 11 && (digits.startsWith('7') || digits.startsWith('8'))) {
    digits = digits.substring(1);
  } else if (digits.length > 10) {
    // 12+ цифр — отбросим всё, что после первых 10. Если первая цифра 7/8 и
    // длина строго 11, мы бы поймали выше; иначе берём префикс.
    if (digits.startsWith('7') || digits.startsWith('8')) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) digits = digits.substring(0, 10);
  }
  return digits;
}

String _formatLocal(String raw) {
  final digits = _localDigits(raw);
  if (digits.isEmpty) return '';
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i == 0) buf.write('(');
    if (i == 3) buf.write(') ');
    if (i == 6) buf.write('-');
    if (i == 8) buf.write('-');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// Конвертирует значение поля в E.164 RU. Возвращает `''`, если в поле меньше
/// 10 цифр (то есть номер невалиден и слать его на бекенд нельзя).
String phoneToE164(String controllerText) {
  final digits = _localDigits(controllerText);
  if (digits.length != 10) return '';
  return '+7$digits';
}

/// Валидация: ровно 10 локальных цифр.
bool isValidPhoneE164(String controllerText) {
  return _localDigits(controllerText).length == 10;
}
