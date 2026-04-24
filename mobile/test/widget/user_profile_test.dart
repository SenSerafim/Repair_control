import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/core/access/system_role.dart';
import 'package:repair_control/features/profile/domain/user_profile.dart';

void main() {
  group('UserProfile.parse', () {
    test('минимальный JSON', () {
      final p = UserProfile.parse({
        'id': 'u1',
        'phone': '+79991234567',
        'firstName': 'Иван',
        'lastName': 'Петров',
        'language': 'ru',
      });
      expect(p.id, 'u1');
      expect(p.firstName, 'Иван');
      expect(p.activeRole, isNull);
      expect(p.roles, isEmpty);
    });

    test('полный JSON с roles', () {
      final p = UserProfile.parse({
        'id': 'u1',
        'phone': '+79991234567',
        'firstName': 'Иван',
        'lastName': 'Петров',
        'language': 'ru',
        'activeRole': 'contractor',
        'roles': [
          {
            'role': 'contractor',
            'addedAt': '2026-04-22T10:00:00Z',
            'isActive': true,
          },
          {
            'role': 'master',
            'addedAt': '2026-04-22T11:00:00Z',
            'isActive': false,
          },
        ],
      });
      expect(p.activeRole, SystemRole.contractor);
      expect(p.roles.length, 2);
      expect(p.roles.first.role, SystemRole.contractor);
      expect(p.roles.first.isActive, isTrue);
    });
  });

  group('UserProfileX', () {
    test('fullName', () {
      final p = _profile(firstName: 'Ivan', lastName: 'Petrov');
      expect(p.fullName, 'Ivan Petrov');
    });

    test('initials', () {
      final p = _profile(firstName: 'Иван', lastName: 'Петров');
      expect(p.initials, 'ИП');
    });

    test('initials для пустых полей', () {
      final p = _profile(firstName: '', lastName: '');
      expect(p.initials, '');
    });
  });
}

UserProfile _profile({required String firstName, required String lastName}) {
  return UserProfile(
    id: 'x',
    phone: '+70000000000',
    firstName: firstName,
    lastName: lastName,
    language: 'ru',
  );
}
