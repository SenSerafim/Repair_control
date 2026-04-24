import 'package:flutter/services.dart';

/// Форматирует ввод телефона в E.164 RU-подобный вид: +7 XXX XXX XX XX.
/// Бекенд принимает `^\+?[0-9]{10,15}$` — мы собираем чистые цифры.
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 15) digits = digits.substring(0, 15);

    final buf = StringBuffer('+');
    final bodyLen = digits.length;
    for (var i = 0; i < bodyLen; i++) {
      if (i == 1 || i == 4 || i == 7 || i == 9) buf.write(' ');
      buf.write(digits[i]);
    }
    final formatted = digits.isEmpty ? '' : buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Извлекает чистый E.164 из отформатированного ввода.
/// Если пользователь ввёл 11 цифр начиная с `8` или `7` — превращаем в `+7`.
String phoneToE164(String formatted) {
  final digits = formatted.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  // 11 digit RU numbers starting with 8 → convert to +7
  if (digits.length == 11 && digits.startsWith('8')) {
    return '+7${digits.substring(1)}';
  }
  return '+$digits';
}

/// Валидация: 10-15 цифр после `+`.
bool isValidPhoneE164(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 10 && digits.length <= 15;
}
