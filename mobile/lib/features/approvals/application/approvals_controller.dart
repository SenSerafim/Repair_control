import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_failure.dart';
import '../../projects/application/project_controller.dart';
import '../../stages/application/stages_controller.dart';
import '../data/approvals_repository.dart';
import '../domain/approval.dart';

class ApprovalsBuckets {
  const ApprovalsBuckets({
    required this.pending,
    required this.history,
  });

  final List<Approval> pending;
  final List<Approval> history;

  ApprovalsBuckets copyWith({
    List<Approval>? pending,
    List<Approval>? history,
  }) =>
      ApprovalsBuckets(
        pending: pending ?? this.pending,
        history: history ?? this.history,
      );

  bool get isEmpty => pending.isEmpty && history.isEmpty;
}

final approvalsControllerProvider = AsyncNotifierProvider.family<
    ApprovalsController, ApprovalsBuckets, String>(
  ApprovalsController.new,
);

class ApprovalsController
    extends FamilyAsyncNotifier<ApprovalsBuckets, String> {
  @override
  Future<ApprovalsBuckets> build(String projectId) async {
    final all = await ref
        .read(approvalsRepositoryProvider)
        .list(projectId: projectId);
    return _bucketize(all);
  }

  ApprovalsBuckets _bucketize(List<Approval> all) {
    final pending = <Approval>[];
    final history = <Approval>[];
    for (final a in all) {
      if (a.status == ApprovalStatus.pending) {
        pending.add(a);
      } else {
        history.add(a);
      }
    }
    pending.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    history.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return ApprovalsBuckets(pending: pending, history: history);
  }

  void _replace(Approval a) {
    final current = state.value;
    if (current == null) return;
    final combined = [
      ...current.pending.where((x) => x.id != a.id),
      ...current.history.where((x) => x.id != a.id),
      a,
    ];
    state = AsyncData(_bucketize(combined));
  }

  void _invalidateStageAndProject(String? stageId) {
    // После решения по approval меняются: project.semaphore,
    // stage.planApproved / status / workBudget.
    ref
      ..invalidate(projectControllerProvider(arg))
      ..invalidate(stagesControllerProvider(arg));
  }

  Future<AuthFailure?> approve({
    required Approval approval,
    String? comment,
  }) async {
    try {
      final updated = await ref
          .read(approvalsRepositoryProvider)
          .approve(id: approval.id, comment: comment);
      _replace(updated);
      _invalidateStageAndProject(approval.stageId);
      return null;
    } on ApprovalsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> reject({
    required Approval approval,
    required String comment,
  }) async {
    try {
      final updated = await ref
          .read(approvalsRepositoryProvider)
          .reject(id: approval.id, comment: comment);
      _replace(updated);
      _invalidateStageAndProject(approval.stageId);
      return null;
    } on ApprovalsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> resubmit({
    required Approval approval,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final updated = await ref
          .read(approvalsRepositoryProvider)
          .resubmit(id: approval.id, payload: payload);
      _replace(updated);
      return null;
    } on ApprovalsException catch (e) {
      return e.failure;
    }
  }

  Future<AuthFailure?> cancel(Approval approval) async {
    try {
      final updated =
          await ref.read(approvalsRepositoryProvider).cancel(approval.id);
      _replace(updated);
      _invalidateStageAndProject(approval.stageId);
      return null;
    } on ApprovalsException catch (e) {
      return e.failure;
    }
  }
}

/// Детальный провайдер отдельного согласования — используется экраном
/// детали для свежего state с attachments.
final approvalDetailProvider = AsyncNotifierProvider.family<
    ApprovalDetailController, Approval, String>(
  ApprovalDetailController.new,
);

class ApprovalDetailController
    extends FamilyAsyncNotifier<Approval, String> {
  @override
  Future<Approval> build(String approvalId) {
    return ref.read(approvalsRepositoryProvider).get(approvalId);
  }
}
