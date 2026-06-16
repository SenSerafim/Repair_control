import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/core/access/system_role.dart';
import 'package:repair_control/features/chat/application/team_visibility.dart';
import 'package:repair_control/features/projects/domain/membership.dart';

/// NEWFIX-2 §6.1 / Plan task 8.3 — клиентская оборона:
/// заказчик никогда не должен видеть мастеров в команде, даже если бек
/// вернёт их из-за рассогласования фильтра.
void main() {
  Membership member({
    required String id,
    required String userId,
    required String firstName,
    required MembershipRole role,
  }) {
    return Membership(
      id: id,
      projectId: 'p1',
      userId: userId,
      role: role,
      addedAt: DateTime(2026, 6, 8),
      user: ProjectMemberUser(
        id: userId,
        firstName: firstName,
        lastName: 'L',
        phone: '+7$id',
      ),
    );
  }

  final mixed = <Membership>[
    member(
      id: 'm-cust',
      userId: 'u-cust',
      firstName: 'Cust',
      role: MembershipRole.customer,
    ),
    member(
      id: 'm-rep',
      userId: 'u-rep',
      firstName: 'Rep',
      role: MembershipRole.representative,
    ),
    member(
      id: 'm-for',
      userId: 'u-for',
      firstName: 'Foreman',
      role: MembershipRole.foreman,
    ),
    member(
      id: 'm-mas',
      userId: 'u-mas',
      firstName: 'Master',
      role: MembershipRole.master,
    ),
  ];

  group('filterMembershipsForRole', () {
    test('заказчик не видит мастеров', () {
      final out = filterMembershipsForRole(mixed, SystemRole.customer);
      expect(out, hasLength(3));
      expect(
        out.map((m) => m.role).toSet(),
        equals({
          MembershipRole.customer,
          MembershipRole.representative,
          MembershipRole.foreman,
        }),
      );
      expect(
        out.any((m) => m.role == MembershipRole.master),
        isFalse,
        reason: 'Мастеров не должно остаться в списке у заказчика',
      );
    });

    test('бригадир (contractor) видит всех', () {
      final out = filterMembershipsForRole(mixed, SystemRole.contractor);
      expect(out, hasLength(4));
      expect(out, equals(mixed));
    });

    test('мастер видит всех', () {
      final out = filterMembershipsForRole(mixed, SystemRole.master);
      expect(out, hasLength(4));
      expect(out, equals(mixed));
    });

    test('представитель видит всех (фильтр только для customer)', () {
      final out = filterMembershipsForRole(mixed, SystemRole.representative);
      expect(out, hasLength(4));
      expect(out, equals(mixed));
    });

    test('null роль = без фильтрации (на всякий случай: не ломаем UI)', () {
      final out = filterMembershipsForRole(mixed, null);
      expect(out, hasLength(4));
      expect(out, equals(mixed));
    });

    test('пустой список → пустой результат для любой роли', () {
      expect(
        filterMembershipsForRole(<Membership>[], SystemRole.customer),
        isEmpty,
      );
      expect(
        filterMembershipsForRole(<Membership>[], SystemRole.contractor),
        isEmpty,
      );
    });

    test('заказчик: список только из мастеров → пустой выход', () {
      final onlyMasters = [
        member(
          id: 'mm-1',
          userId: 'um-1',
          firstName: 'M1',
          role: MembershipRole.master,
        ),
        member(
          id: 'mm-2',
          userId: 'um-2',
          firstName: 'M2',
          role: MembershipRole.master,
        ),
      ];
      expect(
        filterMembershipsForRole(onlyMasters, SystemRole.customer),
        isEmpty,
      );
    });
  });
}
