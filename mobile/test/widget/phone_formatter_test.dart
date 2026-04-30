import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/auth/presentation/phone_formatter.dart';

void main() {
  group('phoneToE164', () {
    test('10 локальных цифр → +7XXXXXXXXXX', () {
      expect(phoneToE164('9991234567'), '+79991234567');
      expect(phoneToE164('(999) 123-45-67'), '+79991234567');
    });

    test('пустой ввод → пустая строка', () {
      expect(phoneToE164(''), '');
    });

    test('меньше 10 цифр → пустая строка', () {
      expect(phoneToE164('999'), '');
      expect(phoneToE164('(999) 123-45'), '');
    });
  });

  group('isValidPhoneE164', () {
    test('ровно 10 цифр валидно', () {
      expect(isValidPhoneE164('(999) 123-45-67'), isTrue);
      expect(isValidPhoneE164('9991234567'), isTrue);
    });

    test('меньше 10 цифр невалидно', () {
      expect(isValidPhoneE164('999123456'), isFalse);
    });

    test('пусто невалидно', () {
      expect(isValidPhoneE164(''), isFalse);
    });
  });

  group('PhoneInputFormatter', () {
    TextEditingValue apply(String input) =>
        PhoneInputFormatter().formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
            text: input,
            selection: TextSelection.collapsed(offset: input.length),
          ),
        );

    test('paste +7-префикс отбрасывается', () {
      expect(apply('+79991234567').text, '(999) 123-45-67');
    });

    test('paste 8-префикс отбрасывается', () {
      expect(apply('89991234567').text, '(999) 123-45-67');
    });

    test('paste с пробелами и скобками', () {
      expect(apply('+7 (999) 123-45-67').text, '(999) 123-45-67');
      expect(apply('8 999 123 45 67').text, '(999) 123-45-67');
    });

    test('10 цифр форматируются', () {
      expect(apply('9991234567').text, '(999) 123-45-67');
    });

    test('переполнение усекается до 10', () {
      expect(apply('99912345678').text, '(999) 123-45-67');
    });

    test('частичный ввод корректно форматируется', () {
      expect(apply('999').text, '(999');
      expect(apply('9991').text, '(999) 1');
      expect(apply('999123').text, '(999) 123');
      expect(apply('9991234').text, '(999) 123-4');
      expect(apply('999123456').text, '(999) 123-45-6');
    });

    test('пустой ввод даёт пустую строку', () {
      expect(apply('').text, '');
    });
  });
}
