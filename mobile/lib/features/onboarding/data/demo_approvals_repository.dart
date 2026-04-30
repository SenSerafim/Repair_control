import 'package:dio/dio.dart';

import '../../approvals/data/approvals_repository.dart';
import '../../approvals/domain/approval.dart';
import 'demo_data.dart';

/// Mock-репозиторий согласований для демо-тура.
class DemoApprovalsRepository extends ApprovalsRepository {
  DemoApprovalsRepository() : super(Dio());

  @override
  Future<List<Approval>> list({
    required String projectId,
    ApprovalScope? scope,
    ApprovalStatus? status,
    String? addresseeId,
  }) async {
    Iterable<Approval> result = DemoData.approvals;
    if (scope != null) result = result.where((a) => a.scope == scope);
    if (status != null) result = result.where((a) => a.status == status);
    if (addresseeId != null) {
      result = result.where((a) => a.addresseeId == addresseeId);
    }
    return result.toList();
  }

  @override
  Future<Approval> get(String id) async => DemoData.approvalById(id);

  @override
  Future<Approval> create({
    required String projectId,
    required ApprovalScope scope,
    required String addresseeId,
    String? stageId,
    String? stepId,
    Map<String, dynamic>? payload,
    List<String>? attachmentKeys,
  }) async =>
      DemoData.approvals.first;

  @override
  Future<Approval> approve({required String id, String? comment}) async =>
      DemoData.approvalById(id);

  @override
  Future<Approval> reject({required String id, required String comment}) async =>
      DemoData.approvalById(id);

  @override
  Future<Approval> resubmit({
    required String id,
    Map<String, dynamic>? payload,
    List<String>? attachmentKeys,
  }) async =>
      DemoData.approvalById(id);

  @override
  Future<Approval> cancel(String id) async => DemoData.approvalById(id);
}
