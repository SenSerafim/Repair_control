/// Системные роли — соответствуют backend
/// `backend/libs/rbac/src/rbac.types.ts`:
/// `customer | representative | contractor | master | admin`.
///
/// В терминах UI (карточки ролей в регистрации/профиле) используется
/// 4 явные роли (без `admin`):
/// - `customer` — Заказчик
/// - `representative` — Представитель
/// - `contractor` — Бригадир (термин «Подрядчик» — общеотраслевой,
///   в нашей модели это бригадир, ведущий этап)
/// - `master` — Мастер (исполнитель шагов на этапе)
enum SystemRole {
  admin,
  customer,
  representative,
  contractor,
  master;

  /// Отображаемое имя на русском (для UI).
  String get displayName => switch (this) {
        SystemRole.admin => 'Администратор',
        SystemRole.customer => 'Заказчик',
        SystemRole.representative => 'Представитель',
        SystemRole.contractor => 'Бригадир',
        SystemRole.master => 'Мастер',
      };

  /// Краткое описание роли (для регистрации/добавления роли).
  String get description => switch (this) {
        SystemRole.admin => 'Системный администратор',
        SystemRole.customer => 'Создаёт проекты, управляет бюджетом',
        SystemRole.representative =>
          'Доверенное лицо заказчика или бригадира',
        SystemRole.contractor =>
          'Ведёт работы по этапам, нанимает мастеров',
        SystemRole.master => 'Подрядчик · выполняет шаги на этапах',
      };

  /// Только роли, доступные при регистрации (без admin).
  ///
  /// Порядок (Заказчик → Представитель → Бригадир → Мастер) совпадает
  /// с порядком в registration / role-switcher и матрицей прав ТЗ §1.5.
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
