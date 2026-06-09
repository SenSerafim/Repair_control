/// Self-custody модель инструментов (2026-05-12).
///
/// Каждый ToolItem — один физический инструмент. `ownerId` неизменен,
/// `currentHolderId` меняется только через self-claim (никто не назначает
/// инструмент другому).

class PublicUser {
  const PublicUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String firstName;
  final String lastName;

  /// Контактный телефон. Бекенд отдаёт его всем member-ам проекта (Tools API
  /// согласован с MembersService). Может быть пустым/null для устаревших ответов.
  final String? phone;
  final String? avatarUrl;

  /// «Иван Петров» / «Иван» / «Петров» / id-fallback.
  String get displayName {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isEmpty && l.isEmpty) return id;
    return [f, l].where((s) => s.isNotEmpty).join(' ');
  }

  /// Инициалы для аватара-плейсхолдера: «ИП» / «И» / «?».
  String get initials {
    final f = firstName.trim();
    final l = lastName.trim();
    String pick(String s) => s.isEmpty ? '' : s.substring(0, 1).toUpperCase();
    final out = '${pick(f)}${pick(l)}';
    return out.isEmpty ? '?' : out;
  }

  bool get hasPhone => (phone ?? '').trim().isNotEmpty;

  static PublicUser? parseOrNull(Map<String, dynamic>? json) {
    if (json == null) return null;
    return PublicUser(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PublicUser &&
          other.id == id &&
          other.firstName == firstName &&
          other.lastName == lastName &&
          other.phone == phone &&
          other.avatarUrl == avatarUrl);

  @override
  int get hashCode => Object.hash(id, firstName, lastName, phone, avatarUrl);
}

/// NEWFIX §6.1 — состояние инструмента (заполняется владельцем).
enum ToolCondition {
  newTool,
  good,
  worn,
  broken;

  String get apiValue => switch (this) {
    ToolCondition.newTool => 'new_tool',
    ToolCondition.good => 'good',
    ToolCondition.worn => 'worn',
    ToolCondition.broken => 'broken',
  };

  static ToolCondition? fromString(String? raw) {
    switch (raw) {
      case 'new_tool':
        return ToolCondition.newTool;
      case 'good':
        return ToolCondition.good;
      case 'worn':
        return ToolCondition.worn;
      case 'broken':
        return ToolCondition.broken;
      default:
        return null;
    }
  }

  String get displayName => switch (this) {
    ToolCondition.newTool => 'Новый',
    ToolCondition.good => 'Хорошее',
    ToolCondition.worn => 'Изношенный',
    ToolCondition.broken => 'Сломан',
  };
}

/// NEWFIX-2 §7.1 — формальный статус инструмента.
enum ToolStatus {
  inStorage,
  onProject,
  withEmployee;

  String get apiValue => switch (this) {
    ToolStatus.inStorage => 'in_storage',
    ToolStatus.onProject => 'on_project',
    ToolStatus.withEmployee => 'with_employee',
  };

  static ToolStatus fromString(String? raw) {
    switch (raw) {
      case 'on_project':
        return ToolStatus.onProject;
      case 'with_employee':
        return ToolStatus.withEmployee;
      case 'in_storage':
      default:
        return ToolStatus.inStorage;
    }
  }

  String get displayName => switch (this) {
    ToolStatus.inStorage => 'На складе',
    ToolStatus.onProject => 'На объекте',
    ToolStatus.withEmployee => 'У сотрудника',
  };

  /// Короткая форма для фильтр-чипа: «Склад», «Объект», «У сотр.»
  String get filterChipLabel => switch (this) {
    ToolStatus.inStorage => 'На складе',
    ToolStatus.onProject => 'На объекте',
    ToolStatus.withEmployee => 'У сотр.',
  };
}

class ToolItem {
  const ToolItem({
    required this.id,
    required this.ownerId,
    required this.currentHolderId,
    required this.name,
    this.article,
    this.photoKey,
    this.serial,
    this.purchaseDate,
    this.condition,
    this.status = ToolStatus.inStorage,
    this.storageLocation,
    this.assignedEmployeeId,
    this.projectId,
    this.owner,
    this.holder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;

  /// У кого инструмент сейчас. Меняется только через self-claim.
  final String currentHolderId;
  final String name;

  /// NEWFIX-2 §7.1 — артикул производителя.
  final String? article;
  final String? photoKey;
  final String? serial;

  /// NEWFIX §6.1 — дата покупки.
  final DateTime? purchaseDate;

  /// NEWFIX §6.1 — состояние инструмента.
  final ToolCondition? condition;

  /// NEWFIX-2 §7.1 — формальный статус.
  final ToolStatus status;

  /// Свободный текст склада/гаража (для status=in_storage).
  final String? storageLocation;

  /// ID сотрудника, за которым закреплён (для status=with_employee).
  final String? assignedEmployeeId;

  /// Если задан — инструмент привязан к проекту и виден всем участникам.
  /// null — инструмент только в личном профиле владельца (My Tools).
  final String? projectId;

  /// Enriched-поля от бекенда (включены в GET /projects/:id/tools).
  /// На /me/tools обычно null — клиент сам резолвит из users-кеша.
  final PublicUser? owner;
  final PublicUser? holder;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isInProject => projectId != null;
  bool isHeldBy(String userId) => currentHolderId == userId;
  bool isOwnedBy(String userId) => ownerId == userId;

  ToolItem copyWith({
    String? name,
    String? article,
    String? currentHolderId,
    String? photoKey,
    String? serial,
    DateTime? purchaseDate,
    ToolCondition? condition,
    ToolStatus? status,
    String? storageLocation,
    String? assignedEmployeeId,
    String? projectId,
    PublicUser? owner,
    PublicUser? holder,
    DateTime? updatedAt,
  }) => ToolItem(
    id: id,
    ownerId: ownerId,
    currentHolderId: currentHolderId ?? this.currentHolderId,
    name: name ?? this.name,
    article: article ?? this.article,
    photoKey: photoKey ?? this.photoKey,
    serial: serial ?? this.serial,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    condition: condition ?? this.condition,
    status: status ?? this.status,
    storageLocation: storageLocation ?? this.storageLocation,
    assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
    projectId: projectId ?? this.projectId,
    owner: owner ?? this.owner,
    holder: holder ?? this.holder,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static ToolItem parse(Map<String, dynamic> json) => ToolItem(
    id: json['id'] as String,
    ownerId: json['ownerId'] as String? ?? '',
    currentHolderId:
        json['currentHolderId'] as String? ?? json['ownerId'] as String? ?? '',
    name: json['name'] as String,
    article: json['article'] as String?,
    photoKey: json['photoKey'] as String?,
    serial: json['serial'] as String?,
    purchaseDate: json['purchaseDate'] != null
        ? DateTime.parse(json['purchaseDate'] as String)
        : null,
    condition: ToolCondition.fromString(json['condition'] as String?),
    status: ToolStatus.fromString(json['status'] as String?),
    storageLocation: json['storageLocation'] as String?,
    assignedEmployeeId: json['assignedEmployeeId'] as String?,
    projectId: json['projectId'] as String?,
    owner: PublicUser.parseOrNull(json['_owner'] as Map<String, dynamic>?),
    holder: PublicUser.parseOrNull(json['_holder'] as Map<String, dynamic>?),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

/// Иммутабельное событие передачи инструмента.
/// `previousHolderId` = null у первого события (initial при добавлении в проект).
class ToolCustodyEvent {
  const ToolCustodyEvent({
    required this.id,
    required this.toolItemId,
    required this.projectId,
    required this.holderId,
    this.previousHolderId,
    this.note,
    this.holder,
    this.previousHolder,
    required this.createdAt,
  });

  final String id;
  final String toolItemId;
  final String projectId;
  final String holderId;
  final String? previousHolderId;
  final String? note;
  final PublicUser? holder;
  final PublicUser? previousHolder;
  final DateTime createdAt;

  /// true — самое первое событие (инструмент только что появился в проекте).
  bool get isInitial => previousHolderId == null;

  static ToolCustodyEvent parse(Map<String, dynamic> json) => ToolCustodyEvent(
    id: json['id'] as String,
    toolItemId: json['toolItemId'] as String,
    projectId: json['projectId'] as String,
    holderId: json['holderId'] as String,
    previousHolderId: json['previousHolderId'] as String?,
    note: json['note'] as String?,
    holder: PublicUser.parseOrNull(json['_holder'] as Map<String, dynamic>?),
    previousHolder: PublicUser.parseOrNull(
      json['_previousHolder'] as Map<String, dynamic>?,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
