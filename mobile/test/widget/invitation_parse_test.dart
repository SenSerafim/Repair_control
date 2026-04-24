import 'package:flutter_test/flutter_test.dart';
import 'package:repair_control/features/projects/domain/membership.dart';
import 'package:repair_control/features/team/domain/invitation.dart';

void main() {
  group('InvitationStatus.fromString', () {
    test('все значения', () {
      expect(
        InvitationStatus.fromString('pending'),
        InvitationStatus.pending,
      );
      expect(
        InvitationStatus.fromString('accepted'),
        InvitationStatus.accepted,
      );
      expect(
        InvitationStatus.fromString('cancelled'),
        InvitationStatus.cancelled,
      );
      expect(
        InvitationStatus.fromString('expired'),
        InvitationStatus.expired,
      );
    });
    test('unknown → pending', () {
      expect(InvitationStatus.fromString('?'), InvitationStatus.pending);
      expect(InvitationStatus.fromString(null), InvitationStatus.pending);
    });
  });

  group('Invitation.parse', () {
    test('полный JSON', () {
      final inv = Invitation.parse({
        'id': 'i1',
        'projectId': 'p1',
        'phone': '+79991234567',
        'role': 'master',
        'status': 'pending',
        'expiresAt': '2026-04-30T00:00:00Z',
        'createdAt': '2026-04-22T00:00:00Z',
      });
      expect(inv.role, MembershipRole.master);
      expect(inv.status, InvitationStatus.pending);
    });
  });

  group('Membership.parse', () {
    test('с вложенным user', () {
      final m = Membership.parse({
        'id': 'm1',
        'projectId': 'p1',
        'userId': 'u1',
        'role': 'foreman',
        'addedAt': '2026-04-22T00:00:00Z',
        'user': {
          'id': 'u1',
          'firstName': 'Ivan',
          'lastName': 'Petrov',
          'phone': '+79991234567',
        },
      });
      expect(m.role, MembershipRole.foreman);
      expect(m.user?.firstName, 'Ivan');
    });

    test('без user', () {
      final m = Membership.parse({
        'id': 'm1',
        'projectId': 'p1',
        'userId': 'u1',
        'role': 'master',
        'addedAt': '2026-04-22T00:00:00Z',
      });
      expect(m.user, isNull);
    });
  });
}
