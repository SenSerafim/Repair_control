/// P1.5: «Движение средств» проекта — детальный money-flow для заказчика
/// (или представителя с canSeeBudget). Возвращается из
/// `GET /api/projects/:projectId/money-flow`.
class MoneyFlow {
  const MoneyFlow({
    required this.advances,
    required this.distributions,
    required this.approvedSelfpurchases,
    required this.materialPurchases,
    required this.totals,
  });

  factory MoneyFlow.parse(Map<String, dynamic> json) => MoneyFlow(
        advances: (json['advances'] as List<dynamic>? ?? const [])
            .map((e) => AdvanceFlow.parse(e as Map<String, dynamic>))
            .toList(),
        distributions: (json['distributions'] as List<dynamic>? ?? const [])
            .map((e) => DistributionFlow.parse(e as Map<String, dynamic>))
            .toList(),
        approvedSelfpurchases:
            (json['approvedSelfpurchases'] as List<dynamic>? ?? const [])
                .map((e) =>
                    ApprovedSelfpurchaseFlow.parse(e as Map<String, dynamic>))
                .toList(),
        materialPurchases:
            (json['materialPurchases'] as List<dynamic>? ?? const [])
                .map((e) => MaterialPurchaseFlow.parse(e as Map<String, dynamic>))
                .toList(),
        totals: MoneyFlowTotals.parse(
          json['totals'] as Map<String, dynamic>? ?? const {},
        ),
      );

  final List<AdvanceFlow> advances;
  final List<DistributionFlow> distributions;
  final List<ApprovedSelfpurchaseFlow> approvedSelfpurchases;
  final List<MaterialPurchaseFlow> materialPurchases;
  final MoneyFlowTotals totals;

  bool get isEmpty =>
      advances.isEmpty &&
      distributions.isEmpty &&
      approvedSelfpurchases.isEmpty &&
      materialPurchases.isEmpty;
}

class MoneyFlowTotals {
  const MoneyFlowTotals({
    required this.advances,
    required this.distributed,
    required this.undistributed,
    required this.approvedSelfpurchases,
    required this.materials,
  });

  factory MoneyFlowTotals.parse(Map<String, dynamic> json) => MoneyFlowTotals(
        advances: (json['advances'] as num?)?.toInt() ?? 0,
        distributed: (json['distributed'] as num?)?.toInt() ?? 0,
        undistributed: (json['undistributed'] as num?)?.toInt() ?? 0,
        approvedSelfpurchases:
            (json['approvedSelfpurchases'] as num?)?.toInt() ?? 0,
        materials: (json['materials'] as num?)?.toInt() ?? 0,
      );

  final int advances;
  final int distributed;
  final int undistributed;
  final int approvedSelfpurchases;
  final int materials;
}

class AdvanceFlow {
  const AdvanceFlow({
    required this.id,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
  });

  factory AdvanceFlow.parse(Map<String, dynamic> json) => AdvanceFlow(
        id: json['id'] as String,
        toUserId: json['toUserId'] as String,
        toUserName: (json['toUserName'] as String?) ?? '—',
        amount: (json['amount'] as num).toInt(),
        status: json['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(json['createdAt'] as String),
        confirmedAt: json['confirmedAt'] == null
            ? null
            : DateTime.parse(json['confirmedAt'] as String),
      );

  final String id;
  final String toUserId;
  final String toUserName;
  final int amount;
  final String status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
}

class DistributionFlow {
  const DistributionFlow({
    required this.id,
    required this.parentPaymentId,
    required this.fromUserId,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory DistributionFlow.parse(Map<String, dynamic> json) => DistributionFlow(
        id: json['id'] as String,
        parentPaymentId: json['parentPaymentId'] as String?,
        fromUserId: json['fromUserId'] as String,
        toUserId: json['toUserId'] as String,
        toUserName: (json['toUserName'] as String?) ?? '—',
        amount: (json['amount'] as num).toInt(),
        status: json['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final String? parentPaymentId;
  final String fromUserId;
  final String toUserId;
  final String toUserName;
  final int amount;
  final String status;
  final DateTime createdAt;
}

class ApprovedSelfpurchaseFlow {
  const ApprovedSelfpurchaseFlow({
    required this.id,
    required this.byUserId,
    required this.byUserName,
    required this.amount,
    this.comment,
    this.decidedAt,
  });

  factory ApprovedSelfpurchaseFlow.parse(Map<String, dynamic> json) =>
      ApprovedSelfpurchaseFlow(
        id: json['id'] as String,
        byUserId: json['byUserId'] as String,
        byUserName: (json['byUserName'] as String?) ?? '—',
        amount: (json['amount'] as num).toInt(),
        comment: json['comment'] as String?,
        decidedAt: json['decidedAt'] == null
            ? null
            : DateTime.parse(json['decidedAt'] as String),
      );

  final String id;
  final String byUserId;
  final String byUserName;
  final int amount;
  final String? comment;
  final DateTime? decidedAt;
}

class MaterialPurchaseFlow {
  const MaterialPurchaseFlow({
    required this.requestId,
    required this.title,
    required this.totalSpent,
    required this.itemCount,
  });

  factory MaterialPurchaseFlow.parse(Map<String, dynamic> json) =>
      MaterialPurchaseFlow(
        requestId: json['requestId'] as String,
        title: (json['title'] as String?) ?? 'Запрос материалов',
        totalSpent: (json['totalSpent'] as num).toInt(),
        itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      );

  final String requestId;
  final String title;
  final int totalSpent;
  final int itemCount;
}
