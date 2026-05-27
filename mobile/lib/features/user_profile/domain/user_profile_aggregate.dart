/// ТЗ NEWFIX §4: data class агрегата профиля сотрудника.
/// 5 секций + хедер. Без freezed — обычный value-object с parse;
/// генерация лишний шум для read-only DTO одной точки данных.
class UserProfileAggregate {
  const UserProfileAggregate({
    required this.user,
    required this.objects,
    required this.monthStats,
    required this.tools,
    required this.reclamations,
    required this.payouts,
  });

  final UserProfileHeader user;
  final List<UserProfileObject> objects;
  final UserProfileMonthStats monthStats;
  final List<UserProfileTool> tools;
  final UserProfileReclamations reclamations;
  final UserProfilePayouts payouts;

  static UserProfileAggregate parse(Map<String, dynamic> json) {
    return UserProfileAggregate(
      user: UserProfileHeader.parse(json['user'] as Map<String, dynamic>),
      objects: ((json['objects'] as List?) ?? const [])
          .map((e) => UserProfileObject.parse(e as Map<String, dynamic>))
          .toList(growable: false),
      monthStats: UserProfileMonthStats.parse(
        (json['monthStats'] as Map<String, dynamic>?) ?? const {},
      ),
      tools: ((json['tools'] as List?) ?? const [])
          .map((e) => UserProfileTool.parse(e as Map<String, dynamic>))
          .toList(growable: false),
      reclamations: UserProfileReclamations.parse(
        (json['reclamations'] as Map<String, dynamic>?) ?? const {},
      ),
      payouts: UserProfilePayouts.parse(
        (json['payouts'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class UserProfileHeader {
  const UserProfileHeader({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.activeRole,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String activeRole;
  final String? email;
  final String? avatarUrl;

  String get fullName => '$firstName $lastName'.trim();

  static UserProfileHeader parse(Map<String, dynamic> json) => UserProfileHeader(
        id: json['id'] as String,
        firstName: (json['firstName'] as String?) ?? '',
        lastName: (json['lastName'] as String?) ?? '',
        phone: (json['phone'] as String?) ?? '',
        email: json['email'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        activeRole: (json['activeRole'] as String?) ?? '',
      );
}

class UserProfileObject {
  const UserProfileObject({
    required this.projectId,
    required this.title,
    required this.role,
    required this.stages,
  });

  final String projectId;
  final String title;
  final String role;
  final List<UserProfileObjectStage> stages;

  static UserProfileObject parse(Map<String, dynamic> json) => UserProfileObject(
        projectId: json['projectId'] as String,
        title: (json['title'] as String?) ?? '',
        role: (json['role'] as String?) ?? '',
        stages: ((json['stages'] as List?) ?? const [])
            .map((e) => UserProfileObjectStage.parse(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class UserProfileObjectStage {
  const UserProfileObjectStage({
    required this.stageId,
    required this.title,
    required this.orderIndex,
  });

  final String stageId;
  final String title;
  final int orderIndex;

  static UserProfileObjectStage parse(Map<String, dynamic> json) =>
      UserProfileObjectStage(
        stageId: json['stageId'] as String,
        title: (json['title'] as String?) ?? '',
        orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      );
}

class UserProfileMonthStats {
  const UserProfileMonthStats({required this.stepsDoneThisMonth});
  final int stepsDoneThisMonth;
  static UserProfileMonthStats parse(Map<String, dynamic> json) =>
      UserProfileMonthStats(
        stepsDoneThisMonth: (json['stepsDoneThisMonth'] as num?)?.toInt() ?? 0,
      );
}

class UserProfileTool {
  const UserProfileTool({
    required this.toolId,
    required this.name,
    this.serial,
    this.photoKey,
  });

  final String toolId;
  final String name;
  final String? serial;
  final String? photoKey;

  static UserProfileTool parse(Map<String, dynamic> json) => UserProfileTool(
        toolId: json['toolId'] as String,
        name: (json['name'] as String?) ?? '',
        serial: json['serial'] as String?,
        photoKey: json['photoKey'] as String?,
      );
}

class UserProfileReclamations {
  const UserProfileReclamations({required this.completed, required this.total});
  final int completed;
  final int total;
  static UserProfileReclamations parse(Map<String, dynamic> json) =>
      UserProfileReclamations(
        completed: (json['completed'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );
}

class UserProfilePayouts {
  const UserProfilePayouts({
    required this.visible,
    required this.monthTotal,
    required this.byProject,
  });

  /// false = viewer не имеет права видеть выплаты этого сотрудника
  /// (заказчик смотрит мастера). UI отрисует «—» вместо сумм.
  final bool visible;
  final int monthTotal;
  final List<UserProfilePayoutsProject> byProject;

  static UserProfilePayouts parse(Map<String, dynamic> json) => UserProfilePayouts(
        visible: json['visible'] as bool? ?? false,
        monthTotal: (json['monthTotal'] as num?)?.toInt() ?? 0,
        byProject: ((json['byProject'] as List?) ?? const [])
            .map((e) =>
                UserProfilePayoutsProject.parse(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class UserProfilePayoutsProject {
  const UserProfilePayoutsProject({
    required this.projectId,
    required this.title,
    required this.amount,
  });

  final String projectId;
  final String title;
  final int amount;

  static UserProfilePayoutsProject parse(Map<String, dynamic> json) =>
      UserProfilePayoutsProject(
        projectId: json['projectId'] as String,
        title: (json['title'] as String?) ?? '',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
      );
}
