import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:repair_control/shared/utils/money.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ru_RU'));

  group('Money.format', () {
    test('0 копеек', () {
      expect(Money.format(0), '0 ₽');
    });

    test('ровные рубли', () {
      expect(Money.format(125_000_00), '125 000 ₽');
    });

    test('миллион', () {
      expect(Money.format(1_250_000_00), '1 250 000 ₽');
    });

    test('с дробью при decimals=2', () {
      expect(Money.format(123_45, decimals: 2), '123,45 ₽');
    });

    test('другая валюта', () {
      expect(Money.format(1_000_00, currency: r'$'), r'1 000 $');
    });
  });

  group('Money.parseInputToKopecks', () {
    test('пустая строка → null', () {
      expect(Money.parseInputToKopecks(''), isNull);
      expect(Money.parseInputToKopecks('   '), isNull);
    });

    test('целое с пробелами', () {
      expect(Money.parseInputToKopecks('1 250 000'), 1_250_000_00);
    });

    test('с ₽', () {
      expect(Money.parseInputToKopecks('1 250 000 ₽'), 1_250_000_00);
    });

    test('с дробью через запятую', () {
      expect(Money.parseInputToKopecks('1 250,50'), 1_250_50);
    });

    test('с дробью через точку', () {
      expect(Money.parseInputToKopecks('1250.75'), 1_250_75);
    });

    test('только мусор → null', () {
      expect(Money.parseInputToKopecks('абвгд'), isNull);
    });
  });
}
