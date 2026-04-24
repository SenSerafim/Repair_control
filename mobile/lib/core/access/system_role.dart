/// Системные роли — соответствуют backend
/// `backend/libs/rbac/src/rbac.types.ts`:
/// `customer | representative | contractor | master | admin`.
enum SystemRole {
  admin,
  customer,
  representative,
  contractor,
  master;

  /// Отображаемое имя на русском (для UI списка ролей).
  String get displayName => switch (this) {
        SystemRole.admin => 'Администратор',
        SystemRole.customer => 'Заказчик',
        SystemRole.representative => 'Представитель',
        SystemRole.contractor => 'Бригадир',
        SystemRole.master => 'Мастер',
      };

  /// Только роли, доступные при регистрации (без admin).
  static const registerable = [
    SystemRole.customer,
    SystemRole.representative,
    SystemRole.contractor,
    SystemRole.master,
  ];

  static SystemRole? fromString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final r in SystemRole.values) {
      if (r.name.toLowerCase() == raw.toLowerCase()) return r;
    }
    return null;
  }
}
