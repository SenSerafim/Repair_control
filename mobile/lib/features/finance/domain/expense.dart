/// ТЗ NEWFIX §5: расход проекта/этапа. Без freezed: read-only DTO,
/// codegen для одной записи был бы избыточным шумом.
enum ExpenseCategory {
  materials,
  transport,
  rental,
  services,
  other;

  String get apiValue {
    switch (this) {
      case ExpenseCategory.materials:
        return 'materials';
      case ExpenseCategory.transport:
        return 'transport';
      case ExpenseCategory.rental:
        return 'rental';
      case ExpenseCategory.services:
        return 'services';
      case ExpenseCategory.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case ExpenseCategory.materials:
        return 'Материалы';
      case ExpenseCategory.transport:
        return 'Транспорт';
      case ExpenseCategory.rental:
        return 'Аренда';
      case ExpenseCategory.services:
        return 'Услуги';
      case ExpenseCategory.other:
        return 'Прочее';
    }
  }

  static ExpenseCategory fromApi(String? raw) {
    switch (raw) {
      case 'materials':
        return ExpenseCategory.materials;
      case 'transport':
        return ExpenseCategory.transport;
      case 'rental':
        return ExpenseCategory.rental;
      case 'services':
        return ExpenseCategory.services;
      default:
        return ExpenseCategory.other;
    }
  }
}

class Expense {
  const Expense({
    required this.id,
    required this.projectId,
    required this.category,
    required this.name,
    required this.amount,
    required this.createdAt,
    this.stageId,
    this.comment,
    this.photoKey,
  });

  final String id;
  final String projectId;
  final String? stageId;
  final ExpenseCategory category;
  final String name;
  final int amount;
  final String? comment;
  final String? photoKey;
  final DateTime createdAt;

  static Expense parse(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    projectId: json['projectId'] as String,
    stageId: json['stageId'] as String?,
    category: ExpenseCategory.fromApi(json['category'] as String?),
    name: (json['name'] as String?) ?? '',
    amount: (json['amount'] as num?)?.toInt() ?? 0,
    comment: json['comment'] as String?,
    photoKey: json['photoKey'] as String?,
    createdAt:
        DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
        DateTime.now(),
  );
}
