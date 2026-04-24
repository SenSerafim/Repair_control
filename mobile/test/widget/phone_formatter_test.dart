import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/auth/presentation/phone_formatter.dart';

void main() {
  group('phoneToE164', () {
    test('11-digit starting with 8 → +7', () {
      expect(phoneToE164('89991234567'), '+79991234567');
      expect(phoneToE164('8 999 123 45 67'), '+79991234567');
    });

    test('already +7 → stays', () {
      expect(phoneToE164('+7 999 123 45 67'), '+79991234567');
    });

    test('empty input → empty string', () {
      expect(phoneToE164(''), '');
    });
  });

  group('isValidPhoneE164', () {
    test('11 digits valid', () {
      expect(isValidPhoneE164('+79991234567'), isTrue);
      expect(isValidPhoneE164('89991234567'), isTrue);
    });

    test('too short → invalid', () {
      expect(isValidPhoneE164('+7999'), isFalse);
    });

    test('too long → invalid', () {
      expect(isValidPhoneE164('+7999999999999999'), isFalse);
    });

    test('empty → invalid', () {
      expect(isValidPhoneE164(''), isFalse);
    });
  });
}
