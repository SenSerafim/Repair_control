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
    this.pendingMaterials = const [],
    this.rejectedMaterials = const [],
    this.rejectedSelfpurchases = const [],
    this.wallet,
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
            .map(
              (e) => ApprovedSelfpurchaseFlow.parse(e as Map<String, dynamic>),
            )
            .toList(),
    materialPurchases: (json['materialPurchases'] as List<dynamic>? ?? const [])
        .map((e) => MaterialPurchaseFlow.parse(e as Map<String, dynamic>))
        .toList(),
    pendingMaterials: (json['pendingMaterials'] as List<dynamic>? ?? const [])
        .map((e) => PendingMaterialFlow.parse(e as Map<String, dynamic>))
        .toList(),
    rejectedMaterials: (json['rejectedMaterials'] as List<dynamic>? ?? const [])
        .map((e) => RejectedMaterialFlow.parse(e as Map<String, dynamic>))
        .toList(),
    rejectedSelfpurchases:
        (json['rejectedSelfpurchases'] as List<dynamic>? ?? const [])
            .map(
              (e) => RejectedSelfpurchaseFlow.parse(e as Map<String, dynamic>),
            )
            .toList(),
    wallet: json['wallet'] == null
        ? null
        : ForemanWallet.parse(json['wallet'] as Map<String, dynamic>),
    totals: MoneyFlowTotals.parse(
      json['totals'] as Map<String, dynamic>? ?? const {},
    ),
  );

  final List<AdvanceFlow> advances;
  final List<DistributionFlow> distributions;
  final List<ApprovedSelfpurchaseFlow> approvedSelfpurchases;
  final List<MaterialPurchaseFlow> materialPurchases;
  final List<PendingMaterialFlow> pendingMaterials;
  final List<RejectedMaterialFlow> rejectedMaterials;
  final List<RejectedSelfpurchaseFlow> rejectedSelfpurchases;
  /// Касса бригадира — заполняется только когда бэк отвечает foreman-срезом
  /// (см. `getForemanMoneyFlow`). Для owner/representative — `null`.
  final ForemanWallet? wallet;
  final MoneyFlowTotals totals;

  bool get isEmpty =>
      advances.isEmpty &&
      distributions.isEmpty &&
      approvedSelfpurchases.isEmpty &&
      materialPurchases.isEmpty &&
      pendingMaterials.isEmpty &&
      rejectedMaterials.isEmpty &&
      rejectedSelfpurchases.isEmpty;
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
    required this.createdAt,
  });

  factory AdvanceFlow.parse(Map<String, dynamic> json) => AdvanceFlow(
    id: json['id'] as String,
    toUserId: json['toUserId'] as String,
    toUserName: (json['toUserName'] as String?) ?? '—',
    amount: (json['amount'] as num).toInt(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  final String id;
  final String toUserId;
  final String toUserName;
  final int amount;
  final DateTime createdAt;
}

class DistributionFlow {
  const DistributionFlow({
    required this.id,
    required this.parentPaymentId,
    required this.fromUserId,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
    required this.createdAt,
  });

  factory DistributionFlow.parse(Map<String, dynamic> json) => DistributionFlow(
    id: json['id'] as String,
    parentPaymentId: json['parentPaymentId'] as String?,
    fromUserId: json['fromUserId'] as String,
    toUserId: json['toUserId'] as String,
    toUserName: (json['toUserName'] as String?) ?? '—',
    amount: (json['amount'] as num).toInt(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  final String id;
  final String? parentPaymentId;
  final String fromUserId;
  final String toUserId;
  final String toUserName;
  final int amount;
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

/// Кто фактически купил материал (см. `MaterialRecipient` на бэке).
enum MaterialBoughtBy { customer, foreman }

class MaterialPurchaseFlow {
  const MaterialPurchaseFlow({
    required this.requestId,
    required this.title,
    required this.totalSpent,
    required this.itemCount,
    this.boughtBy = MaterialBoughtBy.customer,
    this.requestedByName = '—',
  });

  factory MaterialPurchaseFlow.parse(Map<String, dynamic> json) =>
      MaterialPurchaseFlow(
        requestId: json['requestId'] as String,
        title: (json['title'] as String?) ?? 'Запрос материалов',
        totalSpent: (json['totalSpent'] as num).toInt(),
        itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
        boughtBy: switch (json['boughtBy'] as String?) {
          'foreman' => MaterialBoughtBy.foreman,
          _ => MaterialBoughtBy.customer,
        },
        requestedByName: (json['requestedByName'] as String?) ?? '—',
      );

  final String requestId;
  final String title;
  final int totalSpent;
  final int itemCount;
  final MaterialBoughtBy boughtBy;
  final String requestedByName;
}

/// Заявка на материал в статусе `pending_approval` — ждёт решения заказчика.
/// В spent НЕ попадает, отображается отдельной секцией «На согласовании».
class PendingMaterialFlow {
  const PendingMaterialFlow({
    required this.requestId,
    required this.title,
    required this.estimatedTotal,
    required this.itemCount,
    required this.requestedByName,
    required this.createdAt,
  });

  factory PendingMaterialFlow.parse(Map<String, dynamic> json) =>
      PendingMaterialFlow(
        requestId: json['requestId'] as String,
        title: (json['title'] as String?) ?? 'Запрос материалов',
        estimatedTotal: (json['estimatedTotal'] as num?)?.toInt() ?? 0,
        itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
        requestedByName: (json['requestedByName'] as String?) ?? '—',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String requestId;
  final String title;
  final int estimatedTotal;
  final int itemCount;
  final String requestedByName;
  final DateTime createdAt;
}

/// Отклонённая (или отозванная) заявка на материал — status=cancelled.
class RejectedMaterialFlow {
  const RejectedMaterialFlow({
    required this.requestId,
    required this.title,
    required this.estimatedTotal,
    required this.itemCount,
    required this.requestedByName,
    required this.decidedAt,
  });

  factory RejectedMaterialFlow.parse(Map<String, dynamic> json) =>
      RejectedMaterialFlow(
        requestId: json['requestId'] as String,
        title: (json['title'] as String?) ?? 'Запрос материалов',
        estimatedTotal: (json['estimatedTotal'] as num?)?.toInt() ?? 0,
        itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
        requestedByName: (json['requestedByName'] as String?) ?? '—',
        decidedAt: DateTime.parse(json['decidedAt'] as String),
      );

  final String requestId;
  final String title;
  final int estimatedTotal;
  final int itemCount;
  final String requestedByName;
  final DateTime decidedAt;
}

/// Отклонённый самозакуп — status=rejected.
class RejectedSelfpurchaseFlow {
  const RejectedSelfpurchaseFlow({
    required this.id,
    required this.byUserName,
    required this.amount,
    this.comment,
    this.decidedAt,
  });

  factory RejectedSelfpurchaseFlow.parse(Map<String, dynamic> json) =>
      RejectedSelfpurchaseFlow(
        id: json['id'] as String,
        byUserName: (json['byUserName'] as String?) ?? '—',
        amount: (json['amount'] as num).toInt(),
        comment: json['comment'] as String?,
        decidedAt: json['decidedAt'] == null
            ? null
            : DateTime.parse(json['decidedAt'] as String),
      );

  final String id;
  final String byUserName;
  final int amount;
  final String? comment;
  final DateTime? decidedAt;
}

/// Касса бригадира — `advancesReceived − distributed = available`.
/// `available` может быть отрицательным (бригадир перераспределил больше,
/// чем получил от заказчика) — это допустимо, см. ТЗ §4.2.
class ForemanWallet {
  const ForemanWallet({
    required this.advancesReceived,
    required this.distributed,
    required this.available,
  });

  factory ForemanWallet.parse(Map<String, dynamic> json) => ForemanWallet(
    advancesReceived: (json['advancesReceived'] as num?)?.toInt() ?? 0,
    distributed: (json['distributed'] as num?)?.toInt() ?? 0,
    available: (json['available'] as num?)?.toInt() ?? 0,
  );

  final int advancesReceived;
  final int distributed;
  final int available;
}
