import 'domain_actions.dart';

/// Делегированные представителю права в проекте — клиентское отражение
/// `backend/libs/rbac/src/rbac.types.ts → RepresentativeRights`.
///
/// `jsonKey` — это ровно та строка, которую принимает `sanitizeRepresentativeRights`
/// на бекенде. Любые другие ключи (например `project.invite_member` или
/// `canSeeProjectBudget`) при PATCH `/api/projects/:id/members/:mid`
/// отбрасываются и в БД сохраняется дефолт `false` для всех 10 прав.
///
/// Поэтому везде, где UI собирает `Map<String, bool>` для отправки на backend,
/// ключами должны быть `RepresentativeRight.jsonKey`, а не `DomainAction.value`.
///
/// `canArchive` сюда НЕ входит: архивирование проекта — эксклюзив заказчика
/// (см. backend rbac.matrix.ts: `project.archive`). Sanitize отказывает
/// при попытке выдать это право представителю.
enum RepresentativeRight {
  canEditStages('canEditStages'),

  /// П2.4 — представитель действует как заказчик: новый этап создаётся
  /// сразу, без stage_create approval. Без этого права создать этап нельзя
  /// (даже с canEditStages — это право редактирования, а не создания).
  canCreateStages('canCreateStages'),

  canApprove('canApprove'),

  canSeeBudget('canSeeBudget'),

  canCreatePayments('canCreatePayments'),

  canManageMaterials('canManageMaterials'),

  canManageTools('canManageTools'),

  canInviteMembers('canInviteMembers'),

  /// П2.12 — представитель может удалять участников из команды.
  /// Без этого права кнопка «Убрать из команды» в карточке скрыта.
  canManageTeam('canManageTeam'),

  /// Делегирование делегирования: представитель может добавить ещё одного
  /// представителя со своими правами. Сужается до подмножества прав
  /// текущего представителя (контролируется на backend).
  canAddRepresentative('canAddRepresentative');

  const RepresentativeRight(this.jsonKey);

  /// Ключ в JSON, который backend ждёт в `Membership.permissions` /
  /// `ProjectInvitation.permissions`. См. `sanitizeRepresentativeRights`
  /// в `backend/libs/rbac/src/representative-rights.ts`.
  final String jsonKey;

  static RepresentativeRight? fromJsonKey(String key) {
    for (final r in values) {
      if (r.jsonKey == key) return r;
    }
    return null;
  }
}

/// Маппинг делегированного флага → набор `DomainAction`, которые этот флаг
/// открывает на клиенте. Источник истины — `backend/libs/rbac/src/rbac.matrix.ts`.
/// Используется в `canInProjectProvider` (`access_guard.dart`).
const Map<RepresentativeRight, List<DomainAction>>
representativeRightToActions = {
  RepresentativeRight.canEditStages: [
    DomainAction.projectEdit,
    DomainAction.stageManage,
    DomainAction.stageStart,
    DomainAction.stagePause,
    DomainAction.stepManage,
    DomainAction.stepAddSubstep,
    DomainAction.stepPhotoUpload,
    DomainAction.financeBudgetEdit,
    DomainAction.documentWrite,
    DomainAction.documentDelete,
  ],
  RepresentativeRight.canCreateStages: [
    // П2.4 — `stage.manage` доступен и без canEditStages, через canCreateStages.
    DomainAction.stageManage,
  ],
  RepresentativeRight.canApprove: [
    DomainAction.approvalRequest,
    DomainAction.approvalDecide,
    DomainAction.selfPurchaseConfirm,
  ],
  RepresentativeRight.canSeeBudget: [
    DomainAction.financeBudgetView,
    // feed.export НЕ маппится сюда: бэкенд (rbac.matrix.ts: 'feed.export')
    // разрешает экспорт ленты любому representative, а объём бюджетных
    // данных в TXT-сводке фильтруется в `FeedService.export` по роли.
    // Соответствующее право у representative включено в дефолтах
    // `AccessGuard._matrix` (см. core/access/access_guard.dart).
  ],
  RepresentativeRight.canCreatePayments: [
    // Создание платежа — как у заказчика. Distribute не выдаём:
    // распределяет всегда parent-получатель аванса (бригадир).
    DomainAction.financePaymentCreateAdvance,
  ],
  RepresentativeRight.canManageMaterials: [
    DomainAction.materialsManage,
    DomainAction.materialFinalize,
  ],
  // Self-custody модель (2026-05-12): инструменты доступны всем member-ам
  // (см. tools.* в matrix). RepresentativeRight.canManageTools оставлен
  // для обратной совместимости — он управляет более тонкими сценариями.
  RepresentativeRight.canManageTools: [
    DomainAction.toolsAddToProject,
    DomainAction.toolsClaim,
  ],
  RepresentativeRight.canInviteMembers: [DomainAction.projectInviteMember],
  RepresentativeRight.canManageTeam: [DomainAction.projectInviteMember],
  RepresentativeRight.canAddRepresentative: [DomainAction.projectInviteMember],
};
