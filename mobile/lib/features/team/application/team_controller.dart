import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_failure.dart';
import '../../projects/domain/membership.dart';
import '../data/team_repository.dart';
import '../domain/invitation.dart';

class TeamState {
  const TeamState({required this.members, required this.invitations});

  final List<Membership> members;
  final List<Invitation> invitations;

  TeamState copyWith({
    List<Membership>? members,
    List<Invitation>? invitations,
  }) => TeamState(
    members: members ?? this.members,
    invitations: invitations ?? this.invitations,
  );

  bool get isEmpty => members.isEmpty && invitations.isEmpty;
}

final teamControllerProvider =
    AsyncNotifierProvider.family<TeamController, TeamState, String>(
      TeamController.new,
    );

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

  // Тянет канонический state с сервера и записывает в `state` напрямую (без
  // invalidateSelf — чтобы избежать flicker в `AsyncLoading` у уже открытых
  // экранов). Вызывается после каждой мутации: гарантирует, что и текущий
  // экран команды, и все остальные, которые watch'ат `teamControllerProvider`
  // (stage assign-sheet, finance picker, chat picker, etc.), видят
  // изменения без перезахода в приложение, даже если WS-broadcast
  // `project:membership_changed` был потерян.
  Future<void> _refresh() async {
    try {
      final repo = ref.read(teamRepositoryProvider);
      final (members, invitations) = await (
        repo.members(arg),
        repo.listInvitations(arg),
      ).wait;
      state = AsyncData(
        TeamState(members: members, invitations: invitations),
      );
    } catch (_) {
      // Мутация уже прошла на сервере; не валим тост-flow из-за refresh-сбоя.
    }
  }

  Future<AuthFailure?> addMember({
    required String userId,
    required MembershipRole role,
    Map<String, bool>? permissions,
    List<String>? stageIds,
    String? specialization,
  }) async {
    try {
      await ref
          .read(teamRepositoryProvider)
          .addMember(
            projectId: arg,
            userId: userId,
            role: role,
            permissions: permissions,
            stageIds: stageIds,
            specialization: specialization,
          );
      await _refresh();
      return null;
    } on TeamException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> removeMember(String membershipId) async {
    try {
      await ref
          .read(teamRepositoryProvider)
          .removeMember(projectId: arg, membershipId: membershipId);
      await _refresh();
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
      await ref
          .read(teamRepositoryProvider)
          .updateMember(
            projectId: arg,
            membershipId: membershipId,
            permissions: permissions,
          );
      await _refresh();
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
      await ref
          .read(teamRepositoryProvider)
          .invite(projectId: arg, phone: phone, role: role);
      await _refresh();
      return null;
    } on TeamException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> cancelInvitation(String invitationId) async {
    try {
      await ref
          .read(teamRepositoryProvider)
          .cancelInvitation(projectId: arg, invitationId: invitationId);
      await _refresh();
      return null;
    } on TeamException catch (e) {
      return e.failure;
    }
  }
}
