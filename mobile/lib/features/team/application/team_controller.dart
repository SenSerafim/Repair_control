import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_failure.dart';
import '../../projects/domain/membership.dart';
import '../data/team_repository.dart';
import '../domain/invitation.dart';

class TeamState {
  const TeamState({
    required this.members,
    required this.invitations,
  });

  final List<Membership> members;
  final List<Invitation> invitations;

  TeamState copyWith({
    List<Membership>? members,
    List<Invitation>? invitations,
  }) =>
      TeamState(
        members: members ?? this.members,
        invitations: invitations ?? this.invitations,
      );

  bool get isEmpty => members.isEmpty && invitations.isEmpty;
}

final teamControllerProvider = AsyncNotifierProvider.family<
    TeamController, TeamState, String>(TeamController.new);

class TeamController extends FamilyAsyncNotifier<TeamState, String> {
  @override
  Future<TeamState> build(String projectId) async {
    final repo = ref.read(teamRepositoryProvider);
    final (members, invitations) = await (
      repo.members(projectId),
      repo.listInvitations(projectId),
    ).wait;
    return TeamState(members: members, invitations: invitations);
  }

  Future<AuthFailure?> addMember({
    required String userId,
    required MembershipRole role,
    Map<String, bool>? permissions,
    List<String>? stageIds,
  }) async {
    try {
      final m = await ref.read(teamRepositoryProvider).addMember(
            projectId: arg,
            userId: userId,
            role: role,
            permissions: permissions,
            stageIds: stageIds,
          );
      final current = state.value;
      if (current != null) {
        state = AsyncData(current.copyWith(members: [...current.members, m]));
      }
      return null;
    } on TeamException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> removeMember(String membershipId) async {
    try {
      await ref.read(teamRepositoryProvider).removeMember(
            projectId: arg,
            membershipId: membershipId,
          );
      final current = state.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            members:
                current.members.where((m) => m.id != membershipId).toList(),
          ),
        );
      }
      return null;
    } on TeamException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> updatePermissions({
    required String membershipId,
    required Map<String, bool> permissions,
  }) async {
    try {
      final m = await ref.read(teamRepositoryProvider).updateMember(
            projectId: arg,
            membershipId: membershipId,
            permissions: permissions,
          );
      final current = state.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            members: current.members
                .map((x) => x.id == m.id ? m : x)
                .toList(),
          ),
        );
      }
      return null;
    } on TeamException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> invite({
    required String phone,
    required MembershipRole role,
  }) async {
    try {
      final inv = await ref
          .read(teamRepositoryProvider)
          .invite(projectId: arg, phone: phone, role: role);
      final current = state.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(invitations: [inv, ...current.invitations]),
        );
      }
      return null;
    } on TeamException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> cancelInvitation(String invitationId) async {
    try {
      await ref.read(teamRepositoryProvider).cancelInvitation(
            projectId: arg,
            invitationId: invitationId,
          );
      final current = state.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            invitations: current.invitations
                .where((i) => i.id != invitationId)
                .toList(),
          ),
        );
      }
      return null;
    } on TeamException catch (e) {
      return e.failure;
    }
  }
}
